pragma Singleton

import Quickshell

// Filter for image locations that other programs hand the shell
// (notification icons and images, album art). Only local images are shown:
// loading an http(s) URL would make the shell fetch it, telling that server
// when you were sent the notification or played the track.
Singleton {
    // `url` if it's a local file (a file:/// URL, or an absolute path, made
    // into one) or an image from one of Quickshell's own providers
    // (image://), otherwise "", so nothing is loaded
    function source(url: string): string {
        if (url.startsWith("/"))
            return "file://" + url
        // file:/// only: a file URL naming a host isn't local
        if (/^file:\/\/\//i.test(url) || /^image:\/\//i.test(url))
            return url
        return ""
    }
}
