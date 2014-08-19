/**
 * Created by jlopez on 8/13/14.
 */
package com.jla.swfextract
{
    import com.jla.air.sys.GetOpt;
    import com.jla.air.sys.System;
    import com.jla.air.cmd.BaseCommand;

    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.filesystem.File;

    public class SwfCommand extends BaseCommand
    {
        private var _concurrency:int = 10;
        private var _ix:int;
        private var _loading:int;

        public function SwfCommand(args:Vector.<String>, optSpec:String ='')
        {
            super(args, 'J:' + optSpec);
        }

        override protected function processOption(go:GetOpt):void
        {
            if (go.opt == 'J')
                _concurrency = int(go.optarg);
        }

        override protected function execute():void
        {
            onBeforeLoad();
            for (var i:int = 0; i < _concurrency; ++i)
                loadOne();
            checkCompletion();
        }

        protected function onBeforeLoad():void
        {
        }

        private function loadOne():SWFLoader
        {
            while (_ix < _args.length)
            {
                var path:String = _args[_ix++];
                var file:File = _outputDirectory ? _outputDirectory.resolvePath(path) : new File(path);
                if (!shouldLoad(file))
                    continue;
                _loading++;
                return new SWFLoader(file, _loadNext);
            }
            return null;
        }

        protected function shouldLoad(file:File):Boolean
        {
            return true;
        }

        private function _loadNext(loader:SWFLoader):void
        {
            loadOne();
            processContent(loader.path, loader.content);
            --_loading;
            checkCompletion();
        }

        protected function processContent(path:File, content:DisplayObject):void
        {
            if (content is MovieClip)
                processMovieClip(path, content as MovieClip)
        }

        protected function processMovieClip(path:File, movieClip:MovieClip):void
        {
        }

        private function checkCompletion():void
        {
            if (_loading == 0)
            {
                commandCompleted();
                System.exit(0);
            }
        }

        protected function commandCompleted():void
        {
        }
    }
}

import flash.display.DisplayObject;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.net.URLRequest;

class SWFLoader
{
    private var _path:File;
    private var _callback:Function;
    private var _loader:Loader;

    public function SWFLoader(path:File, callback:Function)
    {
        _path = path;
        _callback = callback;
        var request:URLRequest = new URLRequest(_path.url);
        _loader = new Loader();
        _loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgress);
        _loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
        _loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
        _loader.load(request);
        //debug("Loading [%s]\n", _path.name);
    }

    private function onIoError(event:IOErrorEvent):void
    {
        //debug("Loading [%s] IOError [%s: %s]\n", _path.name, event.errorID, event.text);
        _callback(null);
    }

    private function onComplete(event:Event):void
    {
        //var content:DisplayObject = _loader.content;
        //debug("Loading [%s] Complete! %sx%s %s\n", _path.name, content.width, content.height, getQualifiedClassName(content));
        _callback(this);
    }

    private function onProgress(event:ProgressEvent):void
    {
        //debug("Loading [%s] %s/%s\n", _path.name, event.bytesLoaded, event.bytesTotal);
    }

    internal function get path():File
    {
        return _path;
    }

    internal function get content():DisplayObject
    {
        return _loader.content;
    }
}