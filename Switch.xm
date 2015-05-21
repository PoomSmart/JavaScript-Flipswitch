#import "FSSwitchDataSource.h"
#import "FSSwitchPanel.h"
#import "../PS.h"
#import <substrate.h>

CFStringRef kJSKey = CFSTR("JavaScriptEnabled");
CFStringRef kJS2Key = CFSTR("WebKitJavaScriptEnabled");
NSString *kSafari = @"com.apple.mobilesafari";
//CFStringRef const kPostNotification = CFSTR("");

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

extern "C" int sandbox_container_path_for_pid(pid_t pid, char *buffer, size_t bufsize);

@implementation JSFSSwitch

- (NSString *)safariDomain
{
	if (!isiOS7Up)
		return kSafari;
	if (self->_safariDomain == NULL) {
		char buffer;
		NSString *_path = nil;
		if (sandbox_container_path_for_pid(getpid(), &buffer, 1024)) {
			if (isiOS8Up) {
				LSApplicationProxy *proxy = [NSClassFromString(@"LSApplicationProxy") applicationProxyForIdentifier:kSafari placeholder:NO];
				NSURL *url = proxy.dataContainerURL;
				_path = url.path;
			} else {
				// dirty API as I could not properly use MobileInstallationLookup
				NSString *cachePath = @"/var/mobile/Library/Caches/com.apple.mobile.installation.plist";
				NSDictionary *cache = [NSDictionary dictionaryWithContentsOfFile:cachePath];
				BOOL success = NO;
				if (cache) {
					NSDictionary *system = cache[@"System"];
					if (system) {
						NSDictionary *safari = system[kSafari];
						if (safari) {
							NSString *container = safari[@"Container"];
							if (container)
								_path = container;
						}
					}
				}
				if (!success)
					NSLog(@"JSFS: (FATAL) error reading cache file.");
			}
		} else {
			NSString *path2 = [[NSString alloc] initWithUTF8String:&buffer];
			_path = path2;
			[path2 release];
		}
		if (_path != nil) {
			_path = [_path stringByAppendingPathComponent:@"Library/Preferences/com.apple.mobilesafari"];
			self->_safariDomain = _path;
		}
	}
	return [self->_safariDomain retain];
}

- (FSSwitchState)stateForSwitchIdentifier:(NSString *)switchIdentifier
{
	Boolean keyExist = NO;
	Boolean enabled = NO;
	if (self.safariDomain != nil) {
		CFPreferencesAppSynchronize((CFStringRef)self.safariDomain);
		CFStringRef key = isiOS8Up ? kJSKey : kJS2Key;
		enabled = CFPreferencesGetAppBooleanValue(key, (CFStringRef)self.safariDomain, &keyExist);
	}
	if (!keyExist)
		return FSSwitchStateOn;
	return enabled ? FSSwitchStateOn : FSSwitchStateOff;
}

- (void)applyState:(FSSwitchState)newState forSwitchIdentifier:(NSString *)switchIdentifier
{
	if (newState == FSSwitchStateIndeterminate)
		return;
	CFBooleanRef enabled = newState == FSSwitchStateOn ? kCFBooleanTrue : kCFBooleanFalse;
	if (self.safariDomain) {
		CFPreferencesSetAppValue(kJSKey, enabled, (CFStringRef)self.safariDomain);
		CFPreferencesSetAppValue(kJS2Key, enabled, (CFStringRef)self.safariDomain);
		//CFPreferencesAppSynchronize((CFStringRef)self.safariDomain);
	}
	//CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kPostNotification, nil, nil, YES);
}

@end
