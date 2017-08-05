#import <Flipswitch/FSSwitchDataSource.h>
#import <Flipswitch/FSSwitchPanel.h>
#import "../PS.h"

CFStringRef kJSKey = CFSTR("JavaScriptEnabled");
CFStringRef kJS2Key = CFSTR("WebKitJavaScriptEnabled");
NSString *kSafari = @"com.apple.mobilesafari";

@interface LSBundleProxy : NSObject
@property(readonly) NSURL *dataContainerURL;
@end

@interface LSApplicationProxy : LSBundleProxy
+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)identifier placeholder:(BOOL)placeholder;
@end

@interface JSFSSwitch : NSObject <FSSwitchDataSource> {
    NSString *_safariDomain;
}
@end

extern "C" int sandbox_container_path_for_pid(pid_t, char *, size_t);

@implementation JSFSSwitch

- (NSString *)safariDomain {
    if (!isiOS7Up)
        return kSafari;
    if (self->_safariDomain == NULL) {
        char buffer;
        NSString *_path = nil;
        if (sandbox_container_path_for_pid(getpid(), &buffer, 1024)) {
            if (isiOS8Up) {
                LSApplicationProxy *proxy = [NSClassFromString(@"LSApplicationProxy") applicationProxyForIdentifier:kSafari placeholder:NO];
                _path = proxy.dataContainerURL.path;
            } else {
                // dirty API as I could not properly use MobileInstallationLookup
                NSDictionary *cache = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Caches/com.apple.mobile.installation.plist"];
                _path = [[[cache objectForKey:@"System"] objectForKey:kSafari] objectForKey:@"Container"];
                if (_path == nil) {
                    NSLog(@"JSFS: (FATAL) error reading cache file.");
                    return nil;
                }
            }
        } else {
            NSString *path2 = [[NSString alloc] initWithUTF8String:&buffer];
            _path = path2;
            [path2 release];
        }
        if (_path) {
            self->_safariDomain = [_path stringByAppendingPathComponent:@"Library/Preferences/com.apple.mobilesafari"];
        }
    }
    return [self->_safariDomain retain];
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier {
    Boolean keyExist = NO;
    Boolean enabled = NO;
    if (self.safariDomain) {
        CFPreferencesAppSynchronize((CFStringRef)self.safariDomain);
        CFStringRef key = isiOS8Up ? kJSKey : kJS2Key;
        enabled = CFPreferencesGetAppBooleanValue(key, (CFStringRef)self.safariDomain, &keyExist);
    }
    if (!keyExist)
        return FSSwitchStateOn;
    return enabled ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier {
    if (newState == FSSwitchStateIndeterminate)
        return;
    CFBooleanRef enabled = newState == FSSwitchStateOn ? kCFBooleanTrue : kCFBooleanFalse;
    if (self.safariDomain) {
        CFPreferencesSetAppValue(kJSKey, enabled, (CFStringRef)self.safariDomain);
        CFPreferencesSetAppValue(kJS2Key, enabled, (CFStringRef)self.safariDomain);
    }
}

@end
