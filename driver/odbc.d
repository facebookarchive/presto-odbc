/*
 * MyDll demonstration of how to write D DLLs.
 */

import core.runtime;
import std.c.stdio;
import std.c.stdlib;
import std.string;
import std.c.windows.windows;

__gshared HINSTANCE g_hInst;

extern (Windows) BOOL DllMain(HINSTANCE hInstance, ULONG ulReason, LPVOID pvReserved)
{
    ++dllInitCount;
    switch (ulReason)
    {
        case DLL_PROCESS_ATTACH:
            printf("DLL_PROCESS_ATTACH\n");
            Runtime.initialize();
            break;

        case DLL_PROCESS_DETACH:
            printf("DLL_PROCESS_DETACH\n");
            Runtime.terminate();
            break;

        case DLL_THREAD_ATTACH:
            printf("DLL_THREAD_ATTACH\n");
            return false;

        case DLL_THREAD_DETACH:
            printf("DLL_THREAD_DETACH\n");
            return false;

        default:
    }
    g_hInst = hInstance;
    return true;
}

export extern(C) int dllSquare(int x) { return x^^2; }

export extern(C) void dllTest(int x, char* str) {
  printf("Moop: %d %s\n", x, str);
}
