class AV.FileSource extends AV.EventEmitter
    constructor: (@file) ->
        if not FileReader?
            return @emit 'error', 'This browser does not have FileReader support.'
        
        @offset = 0
        @length = @file.size
        @chunkSize = 1 << 20
            
    start: ->
        if @reader
            return @loop() unless @active
        
        @reader = new FileReader
        @active = true
        
        @reader.onload = (e) =>
            buf = new AV.Buffer(new Uint8Array(e.target.result))
            @offset += buf.length
        
            @emit 'data', buf   
            @active = false     
            @loop() if @offset < @length
        
        @reader.onloadend = =>
            if @offset is @length
                @emit 'end'
                @reader = null
        
        @reader.onerror = (e) =>
            @emit 'error', e
        
        @reader.onprogress = (e) =>
            @emit 'progress', (@offset + e.loaded) / @length * 100
        
        @loop()
        
    loop: ->
        @active = true
        @file[slice = 'slice'] or @file[slice = 'webkitSlice'] or @file[slice = 'mozSlice']
        endPos = Math.min(@offset + @chunkSize, @length)
        
        blob = @file[slice](@offset, endPos)
        @reader.readAsArrayBuffer(blob)
        
    pause: ->
        @active = false
        @reader?.abort()
        
    reset: ->
        @pause()
        @offset = 0