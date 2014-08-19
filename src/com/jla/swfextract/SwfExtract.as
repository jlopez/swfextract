/**
 * Created by jlopez on 8/12/14.
 */
package com.jla.swfextract
{
    import com.jla.air.cmd.CommandMain;

    public class SwfExtract extends CommandMain
    {
        public function SwfExtract()
        {
            super({
                extract: ExtractCommand,
                info: InfoCommand
            });
        }

        override protected function usage():void
        {
            error("usage:\n\tswfextract COMMAND [OPTS]");
        }
    }
}
