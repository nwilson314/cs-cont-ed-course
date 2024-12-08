package main

import "core:fmt"
import SDL "vendor:sdl2"

SDL_Offscreen_Buffer :: struct {
    Texture: ^SDL.Texture,
    Memory: rawptr,
    Width: i32,
    Height: i32,
    Pitch: i32,
}

// Constants
MAX_CONTROLLERS :: 4

// Global Variables
GlobalBackbuffer: SDL_Offscreen_Buffer;
ControllerHandles: [MAX_CONTROLLERS] ^SDL.GameController
RumbleHandles: [MAX_CONTROLLERS] ^SDL.Haptic

SDL_Window_Dimension :: struct {
    Width: i32,
    Height: i32,
}

SDLGetWindowDimension :: proc(Window: ^SDL.Window) -> SDL_Window_Dimension {
    Result: SDL_Window_Dimension
    SDL.GetWindowSize(Window, &Result.Width, &Result.Height)

    return Result
}

RenderWeirdGradient :: proc(Buffer: ^SDL_Offscreen_Buffer, BlueOffset: i32, GreenOffset: i32) {
    Width := Buffer.Width
    Height := Buffer.Height
    Pitch := Buffer.Pitch

    Row := (^u8)(Buffer.Memory)
    for Y: i32 = 0; Y < Height; Y += 1 {
        Pixel := (^u32)(Row)
        for X: i32 = 0; X < Width; X += 1 {
            Blue := (u8)(X + BlueOffset)
            Green := (u8)(Y + GreenOffset)
            // C++ *Pixel++ = ((Green << 8) | Blue);
            Pixel^ = u32((u32(Green) << 8) | u32(Blue))
            Pixel = (^u32)(uintptr(Pixel) + size_of(u32))
        }
        Row = (^u8)(uintptr(Row) + uintptr(Pitch))
    }
}

SDLResizeTexture :: proc(Buffer: ^SDL_Offscreen_Buffer, Renderer: ^SDL.Renderer, Width: i32, Height: i32) {
    BytesPerPixel: i32 = 4
    if Buffer.Memory != nil {
        free(Buffer.Memory)
    }
    if Buffer.Texture != nil {
        SDL.DestroyTexture(Buffer.Texture)
    }

    Buffer.Texture = SDL.CreateTexture(
        Renderer,
        SDL.PixelFormatEnum.ARGB8888,
        SDL.TextureAccess.STREAMING,
        Width,
        Height
    )
    Buffer.Width = Width
    Buffer.Height = Height
    Buffer.Pitch = Width * BytesPerPixel
    Buffer.Memory = raw_data(make([]byte, Width * Height * BytesPerPixel))

}

SDLUpdateWindow :: proc(Window: ^SDL.Window, Renderer: ^SDL.Renderer, Buffer: ^SDL_Offscreen_Buffer) {
    SDL.UpdateTexture(
        Buffer.Texture,
        nil,
        Buffer.Memory,
        Buffer.Pitch,
    )

    SDL.RenderCopy(
        Renderer,
        Buffer.Texture,
        nil,
        nil,
    )

    SDL.RenderPresent(Renderer)
}

HandleEvent :: proc(Event: ^SDL.Event) -> bool {
    ShouldQuit := false

    #partial switch Event.type {
        case SDL.EventType.QUIT:
            fmt.println("SDL_QUIT")
            ShouldQuit = true
            break
        case SDL.EventType.KEYDOWN, SDL.EventType.KEYUP:
            fmt.println("SDL_KEYDOWN || SDL_KEYUP")
            KeyCode := Event.key.keysym.sym
            IsDown := Event.key.state == SDL.PRESSED
            WasDown := false
            if Event.key.state == SDL.RELEASED {
                WasDown = true
            } else if Event.key.repeat != 0 {
                WasDown = true
            }

            if Event.key.repeat == 0 {
                #partial switch KeyCode {
                    case SDL.Keycode.W:
                        fmt.println("W")
                        break
                    case SDL.Keycode.A:
                        fmt.println("A")
                        break
                    case SDL.Keycode.S:
                        fmt.println("S")
                        break
                    case SDL.Keycode.D:
                        fmt.println("D")
                        break
                    case SDL.Keycode.Q:
                        fmt.println("Q")
                        break
                    case SDL.Keycode.E:
                        fmt.println("E")
                        break
                    case SDL.Keycode.UP:
                        fmt.println("UP")
                        break
                    case SDL.Keycode.LEFT:
                        fmt.println("LEFT")
                        break
                    case SDL.Keycode.DOWN:
                        fmt.println("DOWN")
                        break
                    case SDL.Keycode.RIGHT:
                        fmt.println("RIGHT")
                        break
                    case SDL.Keycode.ESCAPE:
                        fmt.println("ESCAPE ")
                        if IsDown {
                            fmt.println("IsDown ")
                        }
                        if WasDown {
                            fmt.println("WasDown")
                        }
                        fmt.println("\n")
                        break
                    case SDL.Keycode.SPACE:
                        fmt.println("SPACE")
                        break
                    case:
                }
            }
            break
        case SDL.EventType.WINDOWEVENT:
            #partial switch Event.window.event {
                case SDL.WindowEventID.SIZE_CHANGED:
                    fmt.println("SDL_WINDOWEVENT_SIZE_CHANGED ", Event.window.data1, Event.window.data2)
                    // Window := SDL.GetWindowFromID(Event.window.windowID)
                    // Renderer := SDL.GetRenderer(Window)
                    // SDLResizeTexture(&GlobalBackbuffer, Renderer, Event.window.data1, Event.window.data2)
                    break
                case SDL.WindowEventID.FOCUS_GAINED:
                    fmt.println("SDL_WINDOWEVENT_FOCUS_GAINED")
                    // Window := SDL.GetWindowFromID(Event.window.windowID)
                    // Renderer := SDL.GetRenderer(Window)
                    // SDLUpdateWindow(Window, Renderer, &GlobalBackbuffer)
                    break
                case SDL.WindowEventID.EXPOSED:
                    fmt.println("SDL_WINDOWEVENT_EXPOSED")
                    Window := SDL.GetWindowFromID(Event.window.windowID)
                    Renderer := SDL.GetRenderer(Window)
                    // SDLResizeTexture(&GlobalBackbuffer, Renderer, Event.window.data1, Event.window.data2)
                    SDLUpdateWindow(Window, Renderer, &GlobalBackbuffer)
                    break
                case:
            }
        case:
    }

    return ShouldQuit
}

SDLOpenGameControllers :: proc() {
    MaxJoysticks := SDL.NumJoysticks()
    ControllerIndex := 0


    for JoystickIndex: i32 = 0; JoystickIndex < MaxJoysticks; JoystickIndex += 1 {
        if !SDL.IsGameController(JoystickIndex) {
            continue
        }
        if ControllerIndex >= MAX_CONTROLLERS {
            break
        }
        ControllerHandles[ControllerIndex] = SDL.GameControllerOpen(JoystickIndex)
        RumbleHandles[ControllerIndex] = SDL.HapticOpen(JoystickIndex);

        if RumbleHandles[ControllerIndex] != nil && SDL.HapticRumbleInit(RumbleHandles[ControllerIndex]) != 0 {
            SDL.HapticClose(RumbleHandles[ControllerIndex])
            RumbleHandles[ControllerIndex] = nil
        }

        ControllerIndex += 1
    }
}

SDLCloseGameControllers :: proc() {
    for ControllerIndex: i32 = 0; ControllerIndex < MAX_CONTROLLERS; ControllerIndex += 1 {
        if ControllerHandles[ControllerIndex] != nil {
            SDL.GameControllerClose(ControllerHandles[ControllerIndex])
        }
    }
}

main :: proc() {
    SDL.Init(SDL.INIT_VIDEO | SDL.INIT_GAMECONTROLLER)

    // Initalize Game Controllers:
    SDLOpenGameControllers()
    
    Window: ^SDL.Window = SDL.CreateWindow(
        "Handmade Hero",
        SDL.WINDOWPOS_UNDEFINED,
        SDL.WINDOWPOS_UNDEFINED,
        640,
        480,
        SDL.WINDOW_RESIZABLE
    )
    if Window != nil {
        Renderer: ^SDL.Renderer = SDL.CreateRenderer(
            Window,
            -1,
            SDL.RENDERER_SOFTWARE
        )
        if Renderer != nil {
            Running: bool = true
            Dimension: SDL_Window_Dimension = SDLGetWindowDimension(Window)
            SDLResizeTexture(&GlobalBackbuffer, Renderer, Dimension.Width, Dimension.Height)
            XOffset: i32 = 0;
            YOffset: i32 = 0;
            for Running {
                Event: SDL.Event
                for SDL.PollEvent(&Event) {
                    if HandleEvent(&Event) {
                        Running = false
                    }
                }
                
                for ControllerIndex: i32 = 0; ControllerIndex < MAX_CONTROLLERS; ControllerIndex += 1 {
                    if ControllerHandles[ControllerIndex] != nil  && SDL.GameControllerGetAttached(ControllerHandles[ControllerIndex]) {
                        // NOTE: We have a controller with index ControllerIndex
                        Up := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.DPAD_UP)
                        Down := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.DPAD_DOWN)
                        Left := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.DPAD_LEFT)
                        Right := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.DPAD_RIGHT)
                        Start := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.START)
                        Back := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.BACK)
                        LeftShoulder := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.LEFTSHOULDER)
                        RightShoulder := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.RIGHTSHOULDER)
                        AButton := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.A)
                        BButton := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.B)
                        XButton := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.X)
                        YButton := SDL.GameControllerGetButton(ControllerHandles[ControllerIndex], SDL.GameControllerButton.Y)

                        StickX := SDL.GameControllerGetAxis(ControllerHandles[ControllerIndex], SDL.GameControllerAxis.LEFTX)
                        StickY := SDL.GameControllerGetAxis(ControllerHandles[ControllerIndex], SDL.GameControllerAxis.LEFTY)

                        if AButton > 0 {
                            YOffset += 2
                        }

                        if BButton > 0 {
                            if RumbleHandles[ControllerIndex] != nil {
                                SDL.HapticRumblePlay(RumbleHandles[ControllerIndex], 0.5, 2000)
                            }
                        }

                    } else {
                        // TODO: The controller is not attached
                    }
                }
                RenderWeirdGradient(&GlobalBackbuffer, XOffset, YOffset)
                SDLUpdateWindow(Window, Renderer, &GlobalBackbuffer)
                // XOffset += 1
                // YOffset += 2
            }
        }
    }
    SDLCloseGameControllers()
    SDL.Quit()
}