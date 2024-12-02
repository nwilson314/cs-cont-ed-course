#include "SDL_render.h"
#include "SDL_video.h"
#include <SDL.h>
#include <stdlib.h>
#include <stdint.h>

#ifndef MAP_ANONYMOUS
#define MAP_ANONYMOUS MAP_ANON
#endif

#define internal static
#define local_persist static
#define global_variable static

typedef int8_t int8;
typedef int16_t int16;
typedef int32_t int32;
typedef int64_t int64;

typedef uint8_t uint8;
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef uint64_t uint64;

struct SDL_Offscreen_Buffer {
    // NOTE(casey): Pixels are alwasy 32-bits wide, Memory Order BB GG RR XX
    SDL_Texture *Texture;
    void *Memory;
    int Width;
    int Height;
    int Pitch;
};

struct SDL_Window_Dimension {
    int Width;
    int Height;
};

global_variable SDL_Offscreen_Buffer GlobalBackbuffer;

SDL_Window_Dimension
SDLGetWindowDimension(SDL_Window *Window) {
    SDL_Window_Dimension Result;
    SDL_GetWindowSize(Window, &Result.Width, &Result.Height);
    return (Result);
}

internal void
RenderWeirdGradient(SDL_Offscreen_Buffer Buffer,int BlueOffset, int GreenOffset)
{    
    int Width = (uint8)Buffer.Width;
    int Height = (uint8)Buffer.Height;

    int Pitch = Buffer.Pitch;
    uint8 *Row = (uint8 *)Buffer.Memory;    
    for(int Y = 0; Y < Buffer.Height; ++Y)
    {
        uint32 *Pixel = (uint32 *)Row;
        for(int X = 0; X < Buffer.Width; ++X)
        {
            uint8 Blue = (X + BlueOffset);
            uint8 Green = (Y + GreenOffset);
            
            *Pixel++ = ((Green << 8) | Blue);
        }

        Row += Pitch;
    }
}

internal void
SDLResizeTexture(SDL_Offscreen_Buffer *Buffer,SDL_Renderer *Renderer, int Width, int Height)
{
    int BytesPerPixel = 4;
    if (Buffer->Memory)
    {
        free(Buffer->Memory);
    }
    if (Buffer->Texture)
    {
        SDL_DestroyTexture(Buffer->Texture);
    }

    Buffer->Texture = SDL_CreateTexture(
        Renderer,
        SDL_PIXELFORMAT_ARGB8888,
        SDL_TEXTUREACCESS_STREAMING,
        Width,
        Height
    );
    Buffer->Width = Width;
    Buffer->Height = Height;
    Buffer->Pitch = Width * BytesPerPixel;
    Buffer->Memory = malloc(Width * Height * BytesPerPixel);

}

internal void
SDLUpdateWindow(SDL_Window *Window, SDL_Renderer *Renderer, SDL_Offscreen_Buffer Buffer)
{
    SDL_UpdateTexture(
        Buffer.Texture,
        0,
        Buffer.Memory,
        Buffer.Pitch
    );

    SDL_RenderCopy(
        Renderer,
        Buffer.Texture,
        0,
        0
    );

    SDL_RenderPresent(Renderer);
}

bool HandleEvent(SDL_Event *Event)
{
    bool ShouldQuit = false;

    switch (Event->type)
    {
        case SDL_QUIT:
        {
            printf("SDL_QUIT\n");
            ShouldQuit = true;
        } break;

        case SDL_WINDOWEVENT:
        {
            switch(Event->window.event)
            {
                case SDL_WINDOWEVENT_SIZE_CHANGED:
                {
                    SDL_Window *Window = SDL_GetWindowFromID(Event->window.windowID);
                    SDL_Renderer *Renderer = SDL_GetRenderer(Window);
                    printf("SDL_WINDOWEVENT_SIZE_CHANGED (%d, %d)\n", Event->window.data1, Event->window.data2);
                    SDLResizeTexture(&GlobalBackbuffer, Renderer, Event->window.data1, Event->window.data2);
                } break;

                case SDL_WINDOWEVENT_FOCUS_GAINED:
                {
                    printf("SDL_WINDOWEVENT_FOCUS_GAINED\n");
                } break;

                case SDL_WINDOWEVENT_EXPOSED:
                {
                    SDL_Window *Window = SDL_GetWindowFromID(Event->window.windowID);
                    SDL_Renderer *Renderer = SDL_GetRenderer(Window);
                    SDLUpdateWindow(Window, Renderer, GlobalBackbuffer);
                } break;
            }
        } break;
    }
    return(ShouldQuit);
}

int main(int argc, char *argv[])
{
    if (SDL_Init(SDL_INIT_VIDEO) != 0)
    {
        // TODO: SDL_Init didn't work!
    }

    SDL_Window *Window = SDL_CreateWindow(
        "Handmade Hero",
        SDL_WINDOWPOS_UNDEFINED,
        SDL_WINDOWPOS_UNDEFINED,
        640,
        480,
        SDL_WINDOW_RESIZABLE
    );

    if (Window)
    {
        SDL_Renderer *Renderer = SDL_CreateRenderer(
            Window,
            -1,
            0
        );
        if (Renderer) 
        {
            bool Running = true;
            SDL_Window_Dimension Dimension = SDLGetWindowDimension(Window);
            SDLResizeTexture(&GlobalBackbuffer, Renderer, Dimension.Width, Dimension.Height);
            int XOffset = 0;
            int YOffset = 0;
            while(Running)
            {
                SDL_Event Event;
                while(SDL_PollEvent(&Event))
                {
                    if (HandleEvent(&Event))
                    {
                        Running = false;
                    }
                }
                RenderWeirdGradient(GlobalBackbuffer, XOffset, YOffset);
                SDLUpdateWindow(Window, Renderer, GlobalBackbuffer);

                ++XOffset;
                YOffset += 2;
            }
        }
        else
        {
            // TODO: Logging Renderer failed
        }
        
    }
    else
    {
        // TODO: Logging Window failed
    }
    
    SDL_Quit();
    return(0);
}