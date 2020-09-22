#import "SocialSharePlugin.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
//#import <TwitterKit/TWTRKit.h>

@implementation SocialSharePlugin {
    FlutterMethodChannel* _channel;
    UIDocumentInteractionController* _dic;
    FlutterResult _result;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:@"social_share_plugin"
                                     binaryMessenger:[registrar messenger]];
    SocialSharePlugin* instance = [[SocialSharePlugin alloc] initWithChannel:channel];
    [registrar addApplicationDelegate:instance];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithChannel:(FlutterMethodChannel*)channel {
    self = [super init];
    if(self) {
        _channel = channel;
    }
    return self;
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:
(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    return [[FBSDKApplicationDelegate sharedInstance]
            application:application
            openURL:url
            sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
            annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    BOOL handled =
    [[FBSDKApplicationDelegate sharedInstance] application:application
                                                   openURL:url
                                         sourceApplication:sourceApplication
                                                annotation:annotation];
    return handled;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    _result = result;
    if ([@"getPlatformVersion" isEqualToString:call.method]) {
        result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
    } else if ([@"shareToFeedInstagram" isEqualToString:call.method]) {
        NSURL *instagramURL = [NSURL URLWithString:@"instagram://app"];
        if([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
            [self instagramShare:call.arguments[@"path"]];
            result(nil);
        } else {
            NSString *instagramLink = @"itms-apps://itunes.apple.com/us/app/apple-store/id389801252";
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:instagramLink] options:@{} completionHandler:^(BOOL success) {}];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:instagramLink]];
            }
            result(false);
        }
    }else if([@"shareInstagramStory" isEqualToString:call.method]){
        [self instagramShareStory:call result:_result];
    } else if ([@"shareToFeedFacebook" isEqualToString:call.method]) {
        NSURL *fbURL = [NSURL URLWithString:@"fbapi://"];
        if([[UIApplication sharedApplication] canOpenURL:fbURL]) {
            [self facebookShare:call.arguments[@"path"]];
            result(nil);
        } else {
            NSString *fbLink = @"itms-apps://itunes.apple.com/us/app/apple-store/id284882215";
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbLink] options:@{} completionHandler:^(BOOL success) {}];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbLink]];
            }
            result(false);
        }
    } else if([@"shareToFeedFacebookLink" isEqualToString:call.method]) {
        NSURL *fbURL = [NSURL URLWithString:@"fbapi://"];
        if([[UIApplication sharedApplication] canOpenURL:fbURL]) {
            [self facebookShareLink:call.arguments[@"quote"] url:call.arguments[@"url"]];
            result(nil);
        } else {
            NSString *fbLink = @"itms-apps://itunes.apple.com/us/app/apple-store/id284882215";
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbLink] options:@{} completionHandler:^(BOOL success) {}];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbLink]];
            }
            result(false);
        }
    } else if([@"shareToTwitterLink" isEqualToString:call.method]) {
        NSURL *twitterURL = [NSURL URLWithString:@"twitter://"];
        if([[UIApplication sharedApplication] canOpenURL:twitterURL]) {
            [self twitterShare:call.arguments[@"text"] url:call.arguments[@"url"]];
            result(nil);
        } else {
            NSString *twitterLink = @"itms-apps://itunes.apple.com/us/app/apple-store/id333903271";
            if (@available(iOS 10.0, *)) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitterLink] options:@{} completionHandler:^(BOOL success) {}];
            } else {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:twitterLink]];
            }
            result(false);
        }
    } else if([@"checkInstalledApps" isEqualToString:call.method]){
        result([self checkInstalledApps]);
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)facebookShare:(NSString*)imagePath {
    //NSURL* path = [[NSURL alloc] initWithString:call.arguments[@"path"]];
    FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] init];
    photo.image = [[UIImage alloc] initWithContentsOfFile:imagePath];
    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
    content.photos = @[photo];
    UIViewController* controller = [UIApplication sharedApplication].delegate.window.rootViewController;
    [FBSDKShareDialog showFromViewController:controller withContent:content delegate:self];
}

- (void)facebookShareLink:(NSString*)quote
                      url:(NSString*)url {
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:url];
    content.quote = quote;
    UIViewController* controller = [UIApplication sharedApplication].delegate.window.rootViewController;
    [FBSDKShareDialog showFromViewController:controller withContent:content delegate:self];
}

- (void)instagramShare:(NSString*)imagePath {
    NSError *error = nil;
    UIViewController* controller = [UIApplication sharedApplication].delegate.window.rootViewController;
    [[NSFileManager defaultManager] moveItemAtPath:imagePath toPath:[NSString stringWithFormat:@"%@.igo", imagePath] error:&error];
    NSURL *path = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@.igo", imagePath]];
    _dic = [UIDocumentInteractionController interactionControllerWithURL:path];
    _dic.UTI = @"com.instagram.exclusivegram";
    if (![_dic presentOpenInMenuFromRect:CGRectZero inView:controller.view animated:TRUE]) {
        NSLog(@"Error sharing to instagram");
    };
}

- (void)instagramShareStory:(FlutterMethodCall*)call result:(FlutterResult)result{
    //Sharing story on instagram
    NSString *stickerImage = call.arguments[@"stickerImage"];
    NSString *backgroundTopColor = call.arguments[@"backgroundTopColor"];
    NSString *backgroundBottomColor = call.arguments[@"backgroundBottomColor"];
    NSString *attributionURL = call.arguments[@"attributionURL"];
    NSString *backgroundImage = call.arguments[@"backgroundImage"];
    //getting image from file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isFileExist = [fileManager fileExistsAtPath: stickerImage];
    UIImage *imgShare;
    if (isFileExist) {
        //if image exists
        imgShare = [[UIImage alloc] initWithContentsOfFile:stickerImage];
    }
    //url Scheme for instagram story
    NSURL *urlScheme = [NSURL URLWithString:@"instagram-stories://share"];
    //adding data to send to instagram story
    if ([[UIApplication sharedApplication] canOpenURL:urlScheme]) {
        //if instagram is installed and the url can be opened
        if ( [ backgroundImage  length] == 0 ){
            //If you dont have a background image
            // Assign background image asset and attribution link URL to pasteboard
            NSArray *pasteboardItems = @[@{@"com.instagram.sharedSticker.stickerImage" : imgShare,
                                           @"com.instagram.sharedSticker.backgroundTopColor" : backgroundTopColor,
                                           @"com.instagram.sharedSticker.backgroundBottomColor" : backgroundBottomColor,
                                           @"com.instagram.sharedSticker.contentURL" : attributionURL
            }];
            if (@available(iOS 10.0, *)) {
                NSDictionary *pasteboardOptions = @{UIPasteboardOptionExpirationDate : [[NSDate date] dateByAddingTimeInterval:60 * 5]};
                // This call is iOS 10+, can use 'setItems' depending on what versions you support
                [[UIPasteboard generalPasteboard] setItems:pasteboardItems options:pasteboardOptions];
                
                [[UIApplication sharedApplication] openURL:urlScheme options:@{} completionHandler:nil];
                //if success
                result(@"sharing");
            } else {
                result(@"this only supports iOS 10+");
            }
        }
    }
}

- (void)twitterShare:(NSString*)text
                 url:(NSString*)url {
    UIApplication* application = [UIApplication sharedApplication];
    NSString* shareString = [NSString stringWithFormat:@"https://twitter.com/intent/tweet?text=%@&url=%@", text, url];
    NSString* escapedShareString = [shareString stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    NSURL* shareUrl = [NSURL URLWithString:escapedShareString];
    if (@available(iOS 10.0, *)) {
        [application openURL:shareUrl options:@{} completionHandler:^(BOOL success) {
            if(success) {
                [self->_channel invokeMethod:@"onSuccess" arguments:nil];
                NSLog(@"Sending Tweet!");
            } else {
                [self->_channel invokeMethod:@"onCancel" arguments:nil];
                NSLog(@"Tweet sending cancelled");
            }
        }];
    } else {
        [application openURL:shareUrl];
        [self->_channel invokeMethod:@"onSuccess" arguments:nil];
        NSLog(@"Sending Tweet!");
    }
    //    TWTRComposer *composer = [[TWTRComposer alloc] init];
    //    [composer setText:text];
    //    [composer setURL:[NSURL URLWithString:url]];
    //    [composer showFromViewController:controller completion:^(TWTRComposerResult result) {
    //        if (result == TWTRComposerResultCancelled) {
    //            [self->_channel invokeMethod:@"onCancel" arguments:nil];
    //            NSLog(@"Tweet composition cancelled");
    //        }
    //        else {
    //            [self->_channel invokeMethod:@"onSuccess" arguments:nil];
    //            NSLog(@"Sending Tweet!");
    //        }
    //    }];
}

- (NSMutableDictionary *)checkInstalledApps{
    NSMutableDictionary *installedApps = [[NSMutableDictionary alloc] init];
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"instagram://app"]]) {
        [installedApps setObject:[NSNumber numberWithBool: YES] forKey:@"instagram"];
    }else{
        [installedApps setObject:[NSNumber numberWithBool: NO] forKey:@"instagram"];
    }
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"fbapi://"]]) {
        [installedApps setObject:[NSNumber numberWithBool: YES] forKey:@"facebook"];
    }else{
        [installedApps setObject:[NSNumber numberWithBool: NO] forKey:@"facebook"];
    }
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter://"]]) {
        [installedApps setObject:[NSNumber numberWithBool: YES] forKey:@"twitter"];
    }else{
        [installedApps setObject:[NSNumber numberWithBool: NO] forKey:@"twitter"];
    }
    return installedApps;
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results{
    [_channel invokeMethod:@"onSuccess" arguments:nil];
    NSLog(@"Sharing completed successfully");
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer{
    [_channel invokeMethod:@"onCancel" arguments:nil];
    NSLog(@"Sharing cancelled");
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error{
    [_channel invokeMethod:@"onError" arguments:nil];
    NSLog(@"%@",error);
}

@end
