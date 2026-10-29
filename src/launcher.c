/*
 * Contents/MacOS/mpv of the wrapper app.
 *
 * mpv acts as an app (Finder open events, its own window, bundle mpv.conf)
 * only when MPVBUNDLE=true. LaunchServices ignores the Info.plist's
 * LSEnvironment when the bundle executable is a symlink, so this sets it and
 * execs Contents/MacOS/mpv-formula, the symlink to Homebrew's mpv. exec keeps
 * the PID, so macOS still sees a single io.mpv app.
 */
#include <libgen.h>
#include <limits.h>
#include <mach-o/dyld.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    char self[PATH_MAX], target[PATH_MAX];
    uint32_t size = sizeof(self);
    if (_NSGetExecutablePath(self, &size) != 0) return 1;
    snprintf(target, sizeof(target), "%s/mpv-formula", dirname(self));
    setenv("MPVBUNDLE", "true", 1);
    argv[0] = target;
    execv(target, argv);
    perror(target);
    return 127;
}
