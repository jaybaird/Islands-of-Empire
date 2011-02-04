package util
{

import flash.display.MovieClip;
import flash.display.DisplayObject;
import flash.utils.getDefinitionByName;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;

// This becomes the new "root" of the movie, so it will exist forever.
public class AbstractPreloader extends MovieClip
{
    [Embed(source='/assets/splash/sitelock.png')] private const SITELOCK:Class;
    private var m_firstEnterFrame : Boolean;
    
    public function AbstractPreloader()
    {
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;
            
        stop();
                        
        m_firstEnterFrame = true;
        addEventListener( Event.ENTER_FRAME, onEnterFrame );
    }
    
    // It's possible this function will never be called if the load is instant
    protected function updateLoading( a_percent : Number ) : void {}
    // It's possible this function will never be called if the load is instant
    protected function beginLoading() : void {}
    // It's possible this function will never be called if the load is instant, if beginLoading was called, endLoading will be
    protected function endLoading() : void {}
    protected function get mainClassName() : String { return "Main"; }
        
    private function onEnterFrame(event:Event):void
    {
        if( m_firstEnterFrame )
        {
            m_firstEnterFrame = false;

            if( root.loaderInfo.bytesLoaded >= root.loaderInfo.bytesTotal )
            {
                removeEventListener( Event.ENTER_FRAME, onEnterFrame );
                nextFrame();
                initialize();
            }
            else
            {
                beginLoading();
            }
            
            return;
        }

        if( root.loaderInfo.bytesLoaded >= root.loaderInfo.bytesTotal )
        {
            removeEventListener( Event.ENTER_FRAME, onEnterFrame );
            nextFrame();
            initialize();
            endLoading();
        }
        else
        {
            var percent : Number = root.loaderInfo.bytesLoaded / root.loaderInfo.bytesTotal;
            updateLoading( percent );
        }
    }
        
    private function initialize() : void
    {
        var MainClass:Class = getDefinitionByName( mainClassName ) as Class;
        if( MainClass == null )
        {
            throw new Error( "AbstractPreloader:initialize. There was no class matching that name. Did you remember to override mainClassName?" );
        }
        
        var main : DisplayObject = new MainClass() as DisplayObject;
        if( main == null )
        {
            throw new Error( "AbstractPreloader:initialize. Main class needs to inherit from Sprite or MovieClip." );
        }
        
        addChildAt( main, 0 );
    }
}
}