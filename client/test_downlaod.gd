extends SceneTree

# HTTPClient demo
# This simple class can do HTTP requests; it will not block, but it needs to be polled.

func _init():
    var err = 0
    var http = HTTPClient.new() # Create the Client.
    #https://model-world.oss-cn-shanghai.aliyuncs.com/video/2INItMa1ND4/main.webm
    err = http.connect_to_host("model-world.oss-cn-shanghai.aliyuncs.com", 80) # Connect to host/port.
    assert(err == OK) # Make sure connection is OK.

    # Wait until resolved and connected.
    while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
        http.poll()
        if not OS.has_feature("web"):
            OS.delay_msec(500)
        else:
            yield(Engine.get_main_loop(), "idle_frame")

    
    if http.get_status() == HTTPClient.STATUS_CONNECTED:
        print("connect ok!")
    
    var headers = [
        "User-Agent: Pirulo/1.0 (Godot)",
        "Accept: */*"
    ]

    err = http.request(HTTPClient.METHOD_GET, "/video/BXhAEBSY1wc/main.webm", headers) # Request a page from the site (this one was chunked..)
    assert(err == OK) # Make sure all is OK.

    while http.get_status() == HTTPClient.STATUS_REQUESTING:
        http.poll()
        if OS.has_feature("web"):
            yield(Engine.get_main_loop(), "idle_frame")
        else:
            OS.delay_msec(500)

    if http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED:
        print("response? ", http.has_response())

    if http.has_response():
        headers = http.get_response_headers_as_dictionary() # Get response headers.
        if http.is_response_chunked():
            print("Response is Chunked!")
        else:
            var bl = http.get_response_body_length()
            print("Response Length: ", bl)
        var rb = PoolByteArray()
        var last_rb_size=0
        while http.get_status() == HTTPClient.STATUS_BODY:
            http.poll()
            var chunk = http.read_response_body_chunk()
            if chunk.size() == 0:
                if not OS.has_feature("web"):
                    OS.delay_usec(1000)
                else:
                    yield(Engine.get_main_loop(), "idle_frame")
            else:
                rb = rb + chunk
                if last_rb_size!=int(rb.size()/1024/1024):
                    last_rb_size=int(rb.size()/1024/1024)
                    print(last_rb_size)
        print("bytes got: ", rb.size())
        var f=File.new()
        f.open("user://temp.webm",File.WRITE)
        f.store_buffer(rb)
        f.close()
    quit()
