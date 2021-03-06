package com.gamestudiohx.nes;

import com.babylonhx.materials.textures.DynamicTexture;
import com.gamestudiohx.nes.papu.PAPU;
import com.gamestudiohx.nes.input.InputHandlerDesktop;
//import com.gamestudiohx.nes.input.InputHandlerMobile;
//import com.gamestudiohx.nes.DynamicAudio;



/**
 * ...
 * @author Krtolica Vujadin
 */

typedef HaxedNESConfig = {
	var preferredFrameRate:Int;
	var fpsInterval:Int;
	var showDisplay:Bool;
	var emulateSound:Bool;
	var sampleRate:Int;
}
 
class NES {
	
	public var bmp:DynamicTexture;	
	public var opts(default, null):HaxedNESConfig;
	public var cpu(default, null):CPU;
	public var ppu(default, null):PPU;
	public var papu(default, null):PAPU;
	public var mmap(default, null):MapperDefault;
	public var rom(default, null):ROM;
	public var isRunning(default, null):Bool;	
	//public var dynAudio:DynamicAudio;
	
	//#if desktop
	public var input(default, null):InputHandlerDesktop;
	//#else 
	//public var input(default, null):InputHandlerMobile;
	//#end
	
	var frameTime:Float;	
	var fpsFrameCount:Int;
	var lastFpsTime:Float;
	var lastFrameTime:Float;
	var romData:Dynamic;
	
	var cycles:Int = 0;
	var isInLoop:Bool = true;
	
	
	public function new(bmp:DynamicTexture) {
		this.bmp = bmp;
		
		opts = {
			preferredFrameRate: 60,
			fpsInterval: 500, // Time between updating FPS in ms
			showDisplay: true,
			emulateSound: false,
			sampleRate: 44100 // Sound sample rate in hz	
		};
		
		isRunning = false;
		fpsFrameCount = 0;
		romData = null;
		
		frameTime = 1000 / opts.preferredFrameRate;
		
		cpu = new CPU(this);
		ppu = new PPU(this);
		papu = new PAPU(this);
		mmap = null; // set in loadRom()
		//#if desktop
		input = new InputHandlerDesktop(this);
		//#else
		//input = new InputHandlerMobile(this);
		//#end
	}
	
	public function reset() {
        if (mmap != null) {
            mmap.reset();
        }
		
		/*if(dynAudio != null) {
			dynAudio.destroy();
			dynAudio = null;
		}*/
        
        cpu.reset();
        ppu.reset();
        papu.reset();		
    }
	
	public function start() {       
        if (rom != null && rom.valid) {
            if (!isRunning) {				
                isRunning = true;
                if (opts.emulateSound) {
					/*try {
					dynAudio = new DynamicAudio();
					} catch (err:Dynamic) {
						trace(err);
					}*/
				}
            }
        } 
		else {
            trace("There is no ROM loaded, or it is invalid.");
        }
    }
	
	var frameSkip:Int = 0;
	public function frame() {
		if (isRunning) {			
			ppu.startFrame(); 
			
			cycles = 0;
			isInLoop = true;
			
			while(isInLoop) {
				if (cpu.cyclesToHalt == 0) {
					// Execute a CPU instruction
					cycles = cpu.emulate();
					if (opts.emulateSound) {
						papu.clockFrameCounter(cycles);
					}
					cycles *= 3;
					
				} 
				else {
					if (cpu.cyclesToHalt > 8) {
						cycles = 24;
						if (opts.emulateSound) {
							papu.clockFrameCounter(8);
						}
						cpu.cyclesToHalt -= 8;
					}
					else {
						cycles = cpu.cyclesToHalt * 3;
						if (opts.emulateSound) {
							papu.clockFrameCounter(cpu.cyclesToHalt);
						}
						cpu.cyclesToHalt = 0;
					}
				}				
				
				while (cycles > 0) {
					if(ppu.curX == ppu.spr0HitX && ppu.f_spVisibility == 1 && ppu.scanline - 21 == ppu.spr0HitY) {
						// Set sprite 0 hit flag:
						ppu.setStatusFlag(PPU.STATUS_SPRITE0HIT, true);
					}
					
					if (ppu.requestEndFrame) {
						if (--ppu.nmiCounter == 0) {
							ppu.requestEndFrame = false;
							ppu.startVBlank();
							isInLoop = false;
							break;
						}
					}
					
					ppu.curX++;
					if (ppu.curX == 341) {
						ppu.curX = 0;
						ppu.endScanline();
					}
					
					cycles--;
				}
			}
		}
	}
    	
	public function stop() {
        isRunning = false;
		isInLoop = false;
    }
	
	function reloadRom() {
        if (romData != null) {
            loadRom(romData);
        }
    }
    
    // Loads a ROM file into the CPU and PPU.
    // The ROM file is validated first.
    public function loadRom(data:String):Bool {
        if (isRunning) {
            stop();
        }
        
        // Load ROM file:
        rom = new ROM(this);
        rom.load(data);
        
        if (rom.valid) {
            reset();
            mmap = rom.createMapper();
            if (mmap == null) {
                return false;
            }
			
            mmap.loadROM();
            ppu.setMirroring(rom.getMirroringType());
            romData = data;
        }
		trace(rom.valid);
        return rom.valid;
    }
	
	public function writeAudio(samples:Array<Int>) {
		//dynAudio.write(samples);
	}
    
    function resetFps() {
        lastFpsTime = 0;
        fpsFrameCount = 0;
    }
        
    function toJSON():Dynamic {
        return {
            'romData': romData,
            'cpu': cpu.toJSON(),
            'mmap': mmap.toJSON(),
            'ppu': ppu.toJSON()
        };
    }
    
    function fromJSON(s:Dynamic) {
        loadRom(s.romData);
        cpu.fromJSON(s.cpu);
        mmap.fromJSON(s.mmap);
        ppu.fromJSON(s.ppu);
    }
	
}
