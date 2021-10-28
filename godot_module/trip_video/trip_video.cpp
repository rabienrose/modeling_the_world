#include "trip_video.h"
#include "core/project_settings.h"
#include "packet_queue.h"
#include "set.h"
#include "core/os/os.h"
#include <sstream>
#include <iostream>

static void _unwrap_video_frame(PoolVector<uint8_t> &dest, AVFrame *frame, int width, int height) {
	int frame_size = width * height * 4;
	if (dest.size() != frame_size) {
		dest.resize(frame_size);
	}
	PoolVector<uint8_t>::Write write_access = dest.write();
	uint8_t *write_ptr = write_access.ptr();
	int val = 0;
	for (int y = 0; y < height; y++) {
		memcpy(write_ptr, frame->data[0] + y * frame->linesize[0], width * 4);
		write_ptr += width * 4;
	}
}

int VideoStreamPlaybackTrip::decode_packet(bool b_show)
{
    int response = avcodec_send_packet(vcodec_ctx, pPacket);
    if (response < 0)
    {
        print_line("Error while sending a packet to the decoder");
        return response;
    }
    while (response >= 0)
    {
        response = avcodec_receive_frame(vcodec_ctx, frame_yuv);
        if (response == AVERROR(EAGAIN) || response == AVERROR_EOF)
        {
            break;
        }
        else if (response < 0)
        {
            print_line("Error while receiving a frame from the decoder");
            return response;
        }
        if (response >= 0 && b_show)
        {
			time=frame_yuv->pts;
			sws_scale(sws_ctx, (uint8_t const *const *)frame_yuv->data, frame_yuv->linesize, 0, vcodec_ctx->height, frame_rgb->data, frame_rgb->linesize);
			_unwrap_video_frame(unwrapped_frame, frame_rgb, vcodec_ctx->width, vcodec_ctx->height);
			Ref<Image> img = memnew(Image(texture_size.width, texture_size.height, 0, Image::FORMAT_RGBA8, unwrapped_frame));
			texture->set_data(img);
        }
    }
	
    return 0;
}

bool VideoStreamPlaybackTrip::open_file(const String &p_file) {
	String user_path = OS::get_singleton()->get_user_data_dir();
	if (p_file.find("user://")<0){
		print_line("video file can be only placed in user folder");
		return false;
	}
	String raw_path = p_file.replace_first("user:/", user_path );
	file_name=raw_path;
    AVCodec *pCodec = NULL;
    AVCodecParameters *pCodecParameters = NULL;
	videostream_idx=-1;
	std::wstring ws = file_name.c_str();
	std::string s( ws.begin(), ws.end() );
	print_line(file_name);
	if (avformat_open_input(&format_ctx, s.c_str(), NULL, NULL) != 0)
    {
        print_line("ERROR could not open the file");
        return false;
    }
    if (avformat_find_stream_info(format_ctx, NULL) < 0)
    {
        print_line("ERROR could not get the stream info");
        return false;
    }
    for (int i = 0; i < format_ctx->nb_streams; i++)
    {
        AVCodecParameters *pLocalCodecParameters = NULL;
        pLocalCodecParameters = format_ctx->streams[i]->codecpar;
        AVCodec *pLocalCodec = NULL;
        pLocalCodec = (AVCodec *)avcodec_find_decoder(pLocalCodecParameters->codec_id);
        if (pLocalCodec == NULL)
        {
            print_line("ERROR unsupported codec!");
            continue;
        }
        if (pLocalCodecParameters->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            if (videostream_idx == -1)
            {
                videostream_idx = i;
                pCodec = pLocalCodec;
                pCodecParameters = pLocalCodecParameters;
            }
        }
    }
    if (videostream_idx == -1)
    {
		print_line("cannot find videostream");
        return false;
    }
    vcodec_ctx = avcodec_alloc_context3(pCodec);
    if (!vcodec_ctx)
    {
        print_line("failed to allocated memory for AVCodecContext");
        return false;
    }
    if (avcodec_parameters_to_context(vcodec_ctx, pCodecParameters) < 0)
    {
        print_line("failed to copy codec params to codec context");
        return false;
    }
    if (avcodec_open2(vcodec_ctx, pCodec, NULL) < 0)
    {
        print_line("failed to open codec through avcodec_open2");
        return false;
    }
    frame_yuv = av_frame_alloc();
	frame_rgb = av_frame_alloc();
	frame_buffer_size = av_image_get_buffer_size(AV_PIX_FMT_RGB32,vcodec_ctx->width, vcodec_ctx->height, 1);
	frame_buffer = (uint8_t *)memalloc(frame_buffer_size);
    pPacket = av_packet_alloc();
	int width = vcodec_ctx->width;
	int height = vcodec_ctx->height;
	texture_size=Vector2(width, height);
	std::stringstream ss;
	ss<<"Video Codec: resolution: "<<width<<" : "<<height;
	print_line(ss.str().c_str());
	if (av_image_fill_arrays(frame_rgb->data, frame_rgb->linesize, frame_buffer, AV_PIX_FMT_RGB32, width, height, 1) < 0) {
		return false;
	}
	sws_ctx = sws_getContext(width, height, vcodec_ctx->pix_fmt, width, height, AV_PIX_FMT_RGB0, SWS_BILINEAR, NULL, NULL, NULL);
	texture->create((int)texture_size.width, (int)texture_size.height, Image::FORMAT_RGBA8, Texture::FLAG_FILTER | Texture::FLAG_VIDEO_SURFACE);
	
	return true;
}

void VideoStreamPlaybackTrip::update(float p_delta) {
	while (true){
		if (av_read_frame(format_ctx, pPacket) >= 0){
			if (pPacket->pts >= seek_time){
				decode_packet(true);
				av_packet_unref(pPacket);
				seek_time=0;
				break;
			}else{
				decode_packet(false);
				av_packet_unref(pPacket);
			}
		}
	}
}

VideoStreamPlaybackTrip::VideoStreamPlaybackTrip():
	texture(Ref<ImageTexture>(memnew(ImageTexture))),
	playing(false),
	paused(false),
	seek_time(0),
	time(0){
		format_ctx = avformat_alloc_context();
		if (!format_ctx){
			printf("ERROR could not allocate memory for Format Context");
			return;
		}
	}

VideoStreamPlaybackTrip::~VideoStreamPlaybackTrip() {
	cleanup();
}

void VideoStreamPlaybackTrip::cleanup() {
}

// controls

bool VideoStreamPlaybackTrip::is_playing() const {
	return playing;
}

bool VideoStreamPlaybackTrip::is_paused() const {
	return paused;
}

void VideoStreamPlaybackTrip::play() {
	stop();
	playing = true;
}

void VideoStreamPlaybackTrip::stop() {
	if (playing) {
		seek(0);
	}
	playing = false;
}

static void flush_frames(AVCodecContext* ctx) {
	int ret = avcodec_send_packet(ctx, NULL);
	AVFrame frame = {0};
	if (ret <= 0) {
		do {
			ret = avcodec_receive_frame(ctx, &frame);
		} while (ret != AVERROR_EOF);
	}
	avcodec_flush_buffers(ctx);
}

void VideoStreamPlaybackTrip::seek(float p_time) {
	if (paused==false){
		return;
	}
	if (p_time<0){
		p_time=0;
	}
	int64_t seek_pos =  (int64_t)(p_time * AV_TIME_BASE);
	seek_pos = av_rescale_q(seek_pos, AV_TIME_BASE_Q, format_ctx->streams[videostream_idx]->time_base);
	int re = av_seek_frame(format_ctx, videostream_idx, seek_pos, AVSEEK_FLAG_BACKWARD);
	if (re>=0){
		flush_frames(vcodec_ctx);
	}
	update(0);
}

void VideoStreamPlaybackTrip::set_paused(bool p_paused) {
	paused = p_paused;
}

Ref<Texture> VideoStreamPlaybackTrip::get_texture() const {
	return texture;
}

float VideoStreamPlaybackTrip::get_length() const {
	return 0;
}

float VideoStreamPlaybackTrip::get_playback_position() const {
	double pts = time*av_q2d(format_ctx->streams[videostream_idx]->time_base);
	return pts;
}

bool VideoStreamPlaybackTrip::has_loop() const {
	// TODO: Implement looping?
	return false;
}

void VideoStreamPlaybackTrip::set_loop(bool p_enable) {
	// Do nothing
}

void VideoStreamPlaybackTrip::set_audio_track(int p_idx) {
}

void VideoStreamPlaybackTrip::set_mix_callback(AudioMixCallback p_callback, void *p_userdata) {
}

int VideoStreamPlaybackTrip::get_channels() const {
	return 0;
}

int VideoStreamPlaybackTrip::get_mix_rate() const {
	return 0;
}

/* --- NOTE VideoStreamTrip starts here. ----- */

Ref<VideoStreamPlayback> VideoStreamTrip::instance_playback() {
	Ref<VideoStreamPlaybackTrip> pb = memnew(VideoStreamPlaybackTrip);
	if (pb->open_file(file))
		return pb;
	return NULL;
}

void VideoStreamTrip::set_file(const String &p_file) {
	file = p_file;
}

String VideoStreamTrip::get_file() {
	return file;
}

void VideoStreamTrip::_bind_methods() {

	ClassDB::bind_method(D_METHOD("set_file", "file"), &VideoStreamTrip::set_file);
	ClassDB::bind_method(D_METHOD("get_file"), &VideoStreamTrip::get_file);

	ADD_PROPERTY(PropertyInfo(Variant::STRING, "file", PROPERTY_HINT_NONE, "", PROPERTY_USAGE_NOEDITOR | PROPERTY_USAGE_INTERNAL), "set_file", "get_file");
}

void VideoStreamTrip::set_audio_track(int p_track) {

	audio_track = p_track;
}

/* --- NOTE ResourceFormatLoaderVideoStreamTrip starts here. ----- */

RES ResourceFormatLoaderVideoStreamTrip::load(const String &p_path, const String &p_original_path, Error *r_error) {
	FileAccess *f = FileAccess::open(p_path, FileAccess::READ);
	if (!f) {
		if (r_error) {
			*r_error = ERR_CANT_OPEN;
		}
		return RES();
	}
	memdelete(f);
	VideoStreamTrip *stream = memnew(VideoStreamTrip);
	stream->set_file(p_path);
	Ref<VideoStreamTrip> ogv_stream = Ref<VideoStreamTrip>(stream);
	if (r_error) {
		*r_error = OK;
	}
	return ogv_stream;
}

void ResourceFormatLoaderVideoStreamTrip::get_recognized_extensions(List<String> *p_extensions) const {
}

bool ResourceFormatLoaderVideoStreamTrip::handles_type(const String &p_type) const {
	return ClassDB::is_parent_class(p_type, "VideoStream");
}

String ResourceFormatLoaderVideoStreamTrip::get_resource_type(const String &p_path) const {
	return "";
}
