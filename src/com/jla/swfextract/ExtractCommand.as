/**
 * Created by jlopez on 8/13/14.
 */
package com.jla.swfextract
{
    import com.jla.air.sys.GetOpt;
    import com.jla.air.sys.System;
    import com.jla.air.util.sprintf;

    import flash.display.BitmapData;
    import flash.display.MovieClip;
    import flash.display.PNGEncoderOptions;
    import flash.display.StageQuality;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;

    public class ExtractCommand extends SwfCommand
    {
        private var _outputTemplate:String = "%n/%d.png";
        private var _jsonOutput:Boolean;
        private var _info:Object = {};
        private var _cache:Object = {};
        private var _cacheFile:File;

        public function ExtractCommand(args:Vector.<String>)
        {
            super(args, "t:jc:");
        }

        override protected function processOption(go:GetOpt):void
        {
            if (go.opt == 't')
                _outputTemplate = go.optarg;
            else if (go.opt == 'j')
                _jsonOutput = true;
            else if (go.opt == 'c')
                _cacheFile = new File(go.optarg);
        }

        override protected function processMovieClip(path:File, mc:MovieClip):void
        {
            var bitmapData:BitmapData = new BitmapData(mc.width, mc.height, true);
            var options:PNGEncoderOptions = new PNGEncoderOptions();
            options.fastCompression = false;
            var byteArray:ByteArray = new ByteArray();
            var name:String = System.nameWithoutExtension(path);
            var template:String = _outputTemplate.replace("%n", name);
            if (!_jsonOutput)
                log("Extracting %s (%sx%s)", template.replace("%d", sprintf("[0-%s]", mc.totalFrames - 1)), mc.width, mc.height);
            if (mc)
            {
                var frames:Array = [];
                for (var frame:int = 0; frame < mc.totalFrames; ++frame)
                {
                    mc.gotoAndStop(frame);
                    byteArray.length = 0;
                    bitmapData.fillRect(bitmapData.rect, 0);
                    bitmapData.drawWithQuality(mc, null, null, null, null, true, StageQuality.HIGH_16X16);
                    bitmapData.encode(bitmapData.rect, options, byteArray);
                    var outputName:String = sprintf(template, frame);
                    var outputFile:File = _outputDirectory.resolvePath(outputName);
                    debug("[%s] Rendering frame %s/%s %sx%s %s bytes to %s", path.name, frame, mc.totalFrames, mc.width, mc.height, byteArray.length, outputFile.nativePath);
                    var fs:FileStream = new FileStream();
                    fs.open(outputFile, FileMode.WRITE);
                    fs.writeBytes(byteArray);
                    fs.close();
                    frames.push(_outputDirectory.getRelativePath(outputFile, true));
                }
                var info:Object = {
                    type: 'movieClip',
                    width: mc.width,
                    height: mc.height,
                    frames: frames,
                    name: mc.name,
                    ts: path.modificationDate.time
                };
                var key:String = _outputDirectory.getRelativePath(path, true);
                _info[key] = info;
                _cache[key] = info;
            }
        }

        override protected function commandCompleted():void
        {
            saveCache();
            if (_jsonOutput)
            {
                System.out.println(JSON.stringify(_info, null, 2));
            }
        }

        private function saveCache():void
        {
            var fs:FileStream = new FileStream();
            fs.open(_cacheFile, FileMode.WRITE);
            fs.writeUTFBytes(JSON.stringify(_cache, null, 2));
            fs.close();
        }

        override protected function onBeforeLoad():void
        {
            _cacheFile ||= _outputDirectory.resolvePath('cache.xml');
            if (_cacheFile.exists)
            {
                var fs:FileStream = new FileStream();
                fs.open(_cacheFile, FileMode.READ);
                _cache = JSON.parse(fs.readUTFBytes(_cacheFile.size));
                fs.close();
            }
        }

        override protected function shouldLoad(file:File):Boolean
        {
            var info:Object = _cache[_outputDirectory.getRelativePath(file, true)];
            var cacheValid:Boolean = info && file.modificationDate.time == info.ts;
            if (!cacheValid)
                return true;
            for each (var frame:String in info.frames)
            {
                var frameFile:File = _outputDirectory.resolvePath(frame);
                if (!frameFile.exists)
                    return false;
            }
            _info[_outputDirectory.getRelativePath(file, true)] = info;
            return false;
        }
    }
}
