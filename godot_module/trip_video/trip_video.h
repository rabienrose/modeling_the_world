#ifndef TRIP_VIDEO_STREAM_H
#define TRIP_VIDEO_STREAM_H

#include "core/os/file_access.h"
#include "scene/resources/texture.h"
#include "scene/resources/video_stream.h"
extern "C"
{
	#include <libavcodec/avcodec.h>
	#include <libavformat/avformat.h>
	#include <libavutil/avutil.h>
	#include <libavutil/imgutils.h>
	#include <libavutil/opt.h>
	#include <libswresample/swresample.h>
	#include <libswscale/swscale.h>
}
class PacketQueue;

enum POSITION_TYPE {POS_V_PTS, POS_TIME, POS_A_TIME};

class VideoStreamPlaybackTrip : public VideoStreamPlayback {

	GDCLASS(VideoStreamPlaybackTrip, VideoStreamPlayback);
	AVFormatContext *format_ctx;
	AVCodecContext *vcodec_ctx;
	AVFrame *frame_yuv;
	AVFrame *frame_rgb;
	AVPacket *pPacket;
	struct SwsContext *sws_ctx;
	uint8_t *frame_buffer;
	int videostream_idx;
	int frame_buffer_size;
	PoolVector<uint8_t> unwrapped_frame;
	float time;
	unsigned long drop_frame;
	unsigned long total_frame;
	uint64_t seek_time;
	Ref<ImageTexture> texture;
	bool playing;
	bool paused;
	Vector2 texture_size;
	void cleanup();
	void update_texture();

protected:
	String file_name;

public:
	VideoStreamPlaybackTrip();
	~VideoStreamPlaybackTrip();
	bool open_file(const String &p_file);

	virtual void stop();
	virtual void play();

	virtual bool is_playing() const;

	virtual void set_paused(bool p_paused);
	virtual bool is_paused() const;

	virtual void set_loop(bool p_enable);
	virtual bool has_loop() const;

	virtual float get_length() const;

	virtual float get_playback_position() const;
	virtual void seek(float p_time);

	virtual void set_audio_track(int p_idx);

	virtual Ref<Texture> get_texture() const;
	virtual void update(float p_delta);

	virtual void set_mix_callback(AudioMixCallback p_callback, void *p_userdata);
	virtual int get_channels() const;
	virtual int get_mix_rate() const;
	int decode_packet(bool b_show);
};

class VideoStreamTrip : public VideoStream {

	GDCLASS(VideoStreamTrip, VideoStream);

	String file;
	int audio_track;

protected:
	static void
	_bind_methods();

public:
	void set_file(const String &p_file);
	String get_file();

	virtual void set_audio_track(int p_track);
	virtual Ref<VideoStreamPlayback> instance_playback();

	VideoStreamTrip() {}
};

class ResourceFormatLoaderVideoStreamTrip : public ResourceFormatLoader {
public:
	virtual RES load(const String &p_path, const String &p_original_path = "", Error *r_error = NULL);
	virtual void get_recognized_extensions(List<String> *p_extensions) const;
	virtual bool handles_type(const String &p_type) const;
	virtual String get_resource_type(const String &p_path) const;
};

#endif
