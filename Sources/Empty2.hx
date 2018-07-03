package;

import kha.Assets;
import kha.Color;
import kha.Font;
import kha.Framebuffer;
import kha.Image;
import kha.Scheduler;
import kha.Shaders;
import kha.System;
import kha.arrays.Float32Array;
import kha.graphics1.Graphics4;
import kha.graphics4.BlendingFactor;
import kha.graphics4.ConstantLocation;
import kha.graphics4.IndexBuffer;
import kha.graphics4.PipelineState;
import kha.graphics4.TextureUnit;
import kha.graphics4.Usage;
import kha.graphics4.VertexBuffer;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.graphics5.MipMapFilter;
import kha.graphics5.TextureAddressing;
import kha.graphics5.TextureFilter;
import kha.input.Mouse;
import kha.math.FastMatrix4;

/**
 * ...
 * @author The Mozok Team - Dmitry Hryppa
 */

class Empty2
{
    private var bunnyTex:Image;
	private var bunnyTex2:Image;
    private var font:Font;

    private var bCount:Int = 0;
    private var bunnies:Array<Bunny>;
    private var gravity:Float = 0.5;
    private var maxX:Int;
    private var maxY:Int;
    private var minX:Int;
    private var minY:Int;
	
	private var pipeline:PipelineState;

    //------------------------------------------------
    private var backgroundColor:Int = 0xFF2A3347;
    private var deltaTime:Float = 0.0;
    private var totalFrames:Int = 0;
    private var elapsedTime:Float = 0.0;
    private var previousTime:Float = 0.0;
    private var fps:Int = 0;
	
	var buffer:Image;
	
	var buffers:Array<VertexBuffer>;
	var vertexBuffer:VertexBuffer;
	var transformationBuffer:VertexBuffer;
	var uvsBuffer:VertexBuffer;
	var indexBuffer:IndexBuffer;
	public var MAX_VERTEX_PER_BUFFER:Int = 2500;
	var dataPerVertex:Int = 4;
	var mMvpID:ConstantLocation;
	public var mTextureID:TextureUnit;
	var ratioIndexVertex:Float = 6 / 4;
	private var counter:Int=0;
	var finalViewMatrix:kha.math.FastMatrix4;
	
    //------------------------------------------------

    public function new() 
    {
        Assets.loadEverything(function():Void 
        {
			buffers = new Array();
            font = Assets.fonts.mainfont;
            bunnyTex2 = Assets.images.wabbit_alpha;
			bunnyTex = Image.createRenderTarget(bunnyTex2.width, bunnyTex2.height);
			bunnyTex.g2.begin(true,Color.Transparent);
			bunnyTex.g2.drawImage(bunnyTex2, 0, 0);
			bunnyTex.g2.end();
            
            bunnies = new Array<Bunny>();
            minX = 0;
            maxX = Main.SCREEN_W - bunnyTex.width;
            minY = 0;
            maxY = Main.SCREEN_H - bunnyTex.height;
			
			var uvStructure:VertexStructure = new VertexStructure();
			uvStructure.add("uv", VertexData.Float4);
			uvStructure.instanced = true;
			
			var transformationStructure:VertexStructure = new VertexStructure();
			transformationStructure.add("scaleXRotxMovX", VertexData.Float3);
			transformationStructure.add("scaleYRotYMovY", VertexData.Float3);
			transformationStructure.instanced = true;
			
			pipeline = new PipelineState();
			pipeline.vertexShader = Shaders.simple_instance_vert;
			pipeline.fragmentShader = Shaders.simple_instance_frag;
			var structure = new VertexStructure();
			structure.add("vertexPosition", VertexData.Float2);
			pipeline.inputLayout = [structure,uvStructure,transformationStructure];
			pipeline.blendSource = BlendingFactor.BlendOne;
			pipeline.blendDestination = BlendingFactor.InverseSourceAlpha;
			pipeline.alphaBlendSource = BlendingFactor.BlendOne;
			pipeline.alphaBlendDestination = BlendingFactor.InverseSourceAlpha;
			pipeline.compile();
			
			mMvpID = pipeline.getConstantLocation("projectionMatrix");
			mTextureID = pipeline.getTextureUnit("tex");
			
			finalViewMatrix = FastMatrix4.identity();
			finalViewMatrix=finalViewMatrix.multmat(FastMatrix4.scale(2.0 / 800, -2.0 / 600, 1));
			finalViewMatrix = finalViewMatrix.multmat(FastMatrix4.translation( -800 / 2, 600 / 2, 0));
			finalViewMatrix = finalViewMatrix.multmat(FastMatrix4.scale(1, -1, 1));
			
			
			vertexBuffer=new VertexBuffer(
				4,
				structure, 
				Usage.StaticUsage ,
				0
				);
			var vertex = vertexBuffer.lock();
			
			vertex.set( 0, 0);
			vertex.set( 1, 0);
			
			vertex.set( 2, 1);
			vertex.set( 3, 0);
			
			vertex.set( 4, 0);
			vertex.set( 5, 1);
			
			vertex.set( 6, 1);
			vertex.set( 7, 1);
			
			vertexBuffer.unlock();
			// Create index buffer
			indexBuffer = new IndexBuffer(
				6, 
				Usage.StaticUsage 
			);
			
			// Copy indices to index buffer
			var iData = indexBuffer.lock();
	
			iData[0]= 0;
			iData[1]= 1;
			iData[2]= 2;
			iData[3]= 1;
			iData[4]= 2;
			iData[5]= 3;
		
			indexBuffer.unlock();
			
			
			uvsBuffer = new VertexBuffer(Std.int(MAX_VERTEX_PER_BUFFER/4), uvStructure, Usage.DynamicUsage,1);
			
			
			transformationBuffer = new VertexBuffer(Std.int(MAX_VERTEX_PER_BUFFER/4), transformationStructure, Usage.DynamicUsage,1);
			
            buffers.push(vertexBuffer);
			buffers.push(uvsBuffer);
			buffers.push(transformationBuffer);
            
            Mouse.get().notify(mouseDown, null, null, null);
            Scheduler.addTimeTask(update, 0, 1/60);
            System.notifyOnRender(render);
			buffer = Image.createRenderTarget(800, 600);
			
        });
    }

    private function mouseDown(button:Int, x:Int, y:Int):Void 
    {
        var count:Int = button == 0 ? 1 : 1000;
        for (i in 0...count) {
            var bunny:Bunny = new Bunny();
            bunny.speedX = Math.random() * 5;
            bunny.speedY = Math.random() * 5 - 2.5;
            var scale:Float=(0.5+Math.random()*0.5);
            bunny.scaleX=bunnyTex.width*scale;
            bunny.scaleY=bunnyTex.height*scale;
            bunnies.push(bunny);
        }
        bCount = bunnies.length;
    }

    private function update():Void 
    {
		if (fps>59)
		{
			for (i in 0...100) {
				var bunny:Bunny = new Bunny();
				bunny.speedX = Math.random() * 5;
				bunny.speedY = Math.random() * 5 - 2.5;
				var scale:Float=(0.5+Math.random()*0.5);
				bunny.scaleX=bunnyTex.width*scale;
				bunny.scaleY=bunnyTex.height*scale;
				bunnies.push(bunny);
			}
			bCount = bunnies.length;
		}
        for (i in 0...bunnies.length) {
            var bunny:Bunny = bunnies[i];
            
            bunny.x += bunny.speedX;
            bunny.y += bunny.speedY;
            bunny.speedY += gravity;
            
            if (bunny.x > maxX) {
                bunny.speedX *= -1;
                bunny.x = maxX;
            } else if (bunny.x < minX) {
                bunny.speedX *= -1;
                bunny.x = minX;
            } if (bunny.y > maxY) {
                bunny.speedY *= -0.8;
                bunny.y = maxY;
                if (Math.random() > 0.5) bunny.speedY -= 3 + Math.random() * 4;
            }  else if (bunny.y < minY) {
                bunny.speedY = 0;
                bunny.y = minY;
            }
        }
    }

    public function render(framebuffer:Framebuffer):Void 
    {
        var currentTime:Float = Scheduler.realTime();
        deltaTime = (currentTime - previousTime);
        
        elapsedTime += deltaTime;
        if (elapsedTime >= 1.0) {
            fps = totalFrames;
            totalFrames = 0;
            elapsedTime = 0;
        }
        totalFrames++;
        
		var g4 = buffer.g4;
		g4.begin();
		g4.clear(backgroundColor);
		g4.end();
		
		var  counter:Int = bunnies.length;
		var drawCount:Int = 0;
		var offset:Int = 0;
		
		while(counter>0)
		{
			if (counter <= MAX_VERTEX_PER_BUFFER / 4)
			{
				drawCount = counter;
				counter = 0;
			}else {
				drawCount = Std.int(MAX_VERTEX_PER_BUFFER / 4);
				counter -= drawCount;
			}
			
			
			var uvs = uvsBuffer.lock();
			var transforms = transformationBuffer.lock();
			for (i in 0...drawCount) 
			{
				var bunny = bunnies[i+offset];
				uvs.set(i  * 4 + 0, 0);//uv offset
				uvs.set(i  * 4 + 1, 0);//uv offset
				
				uvs.set(i  * 4 + 2, 1);//uv scale
				uvs.set(i  * 4 + 3, 1);//uv scale

				transforms.set(i * 6 + 0, 26);
				transforms.set(i * 6 + 1, 0);
				transforms.set(i * 6 + 2, bunny.x);
				
				transforms.set(i * 6 + 3, 40);
				transforms.set(i * 6 + 4, 0);
				transforms.set(i * 6 + 5, bunny.y);
			}
			
			uvsBuffer.unlock();
			transformationBuffer.unlock();
			
			offset += drawCount;
			g4.begin();
			g4.setPipeline(pipeline);
			g4.setVertexBuffers(buffers);
			g4.setIndexBuffer(indexBuffer);
			g4.setMatrix(mMvpID, finalViewMatrix);
			g4.setTexture(mTextureID, bunnyTex);
			g4.setTextureParameters(mTextureID, TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
			
			g4.drawIndexedVerticesInstanced(drawCount);
			g4.setImageTexture(mTextureID, null);
			g4.end();
		}
		//g2 rendering
        //buffer.g2.begin(true, backgroundColor);
        //buffer.g2.color = 0xFFFFFFFF;
        //for (bunny in bunnies){
            //buffer.g2.drawScaledImage(bunnyTex, bunny.x, bunny.y,bunny.scaleX,bunny.scaleY);
        //}
        buffer.g2.begin(false);
        buffer.g2.font = font;
        buffer.g2.fontSize = 16;
        buffer.g2.color = 0xFF000000;
        buffer.g2.fillRect(0, 0, Main.SCREEN_W, 20);
        buffer.g2.color = 0xFFFFFFFF;
        buffer.g2.drawString("bunnies: " + bCount + "         fps: " + fps, 10, 2);
        buffer.g2.end();
        
        previousTime = currentTime;
		
		framebuffer.g2.begin();
		framebuffer.g2.drawImage(buffer, 0, 0);
		framebuffer.g2.end();
    }
}
