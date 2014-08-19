/**
 * Created by jlopez on 8/13/14.
 */
package com.jla.swfextract
{
    import com.jla.air.sys.System;

    import flash.display.MovieClip;
    import flash.filesystem.File;

    public class InfoCommand extends SwfCommand
    {
        private var _info:Object = {};

        public function InfoCommand(args:Vector.<String>)
        {
            super(args);
        }

        override protected function processMovieClip(path:File, mc:MovieClip):void
        {
            _info[path.nativePath] = {
                type: 'movieClip',
                width: mc.width,
                height: mc.height,
                frames: mc.totalFrames,
                name: mc.name
            };
        }

        override protected function commandCompleted():void
        {
            System.out.println(JSON.stringify(_info, null, 2));
        }
    }
}
