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

GlobalBackbuffer: SDL_Offscreen_Buffer;

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

main :: proc() {
    SDL.Init(SDL.INIT_VIDEO)
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
                RenderWeirdGradient(&GlobalBackbuffer, XOffset, YOffset)
                SDLUpdateWindow(Window, Renderer, &GlobalBackbuffer)
                // XOffset += 1
                // YOffset += 2
            }
        }
    }
    SDL.Quit()

}