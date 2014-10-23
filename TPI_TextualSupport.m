#import "TPI_TextualSupport.h"
#import "TPI_TextualSupport_MenuController.h"
#import "TPI_TextualSupportHelper.h"

@implementation TPI_TextualSupport
NSMenu *userlistMenu;
NSMenu *inputFieldMenu;
NSDictionary *messageCacheForSupportChannel;
NSMutableArray *userTrackList;

+ (NSMutableArray *)userTrackList {
    if (userTrackList == nil) {
        userTrackList = [@[] mutableCopy];
    }
    return userTrackList;
}

- (void)pluginLoadedIntoMemory {
	userlistMenu = self.menuController.userControlMenu;
    inputFieldMenu = [[mainWindow() inputTextField] menu];
    
    [self overrideExistingMenuItems];
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource: @"messages" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    
    NSMenuItem *textualSupportMenuItems = [[NSMenuItem alloc] init];
	[textualSupportMenuItems setTitle:@"Textual Support"];
	[textualSupportMenuItems setKeyEquivalent:NSStringEmptyPlaceholder];
    NSMenu *textualSupportMenu = [NSMenu new];
	[textualSupportMenu setTitle:@"Textual Support"];
    NSArray *supportMessages = dict[@"userlist"];
    [TPI_TextualSupportHelper addItemsFromArrayToMenu:textualSupportMenu menuItems:supportMessages selector:@selector(postMenuMessage:)];
    [textualSupportMenuItems setSubmenu: textualSupportMenu];
	[userlistMenu addItem:[textualSupportMenuItems copy]];
    
    NSMenuItem *textualInsertLinksMenuItems = [[NSMenuItem alloc] init];
    [textualInsertLinksMenuItems setTitle:@"Insert Support Link"];
    [textualInsertLinksMenuItems setKeyEquivalent:NSStringEmptyPlaceholder];
    NSMenu *textualInsertLinksMenu = [NSMenu new];
    [textualInsertLinksMenuItems setTitle:@"Insert Support Link"];
    NSArray *insertLinkMessages = dict[@"insertlink"];
    [TPI_TextualSupportHelper addItemsFromArrayToMenu:textualInsertLinksMenu menuItems:insertLinkMessages selector:@selector(postLinkToInputField:)];
    [textualInsertLinksMenuItems setSubmenu:textualInsertLinksMenu];
    [inputFieldMenu addItem:[textualInsertLinksMenuItems copy]];
    
    
    NSMenuItem *textualTrackUserMenuItem = [[NSMenuItem alloc] init];
    [textualTrackUserMenuItem setTitle:@"Track User"];
    [textualTrackUserMenuItem setKeyEquivalent:NSStringEmptyPlaceholder];
    [textualTrackUserMenuItem setTarget:menuController()];
    [textualTrackUserMenuItem setAction:@selector(trackUserInitiated:)];
    [textualTrackUserMenuItem setTag:424201];
    [userlistMenu addItem:textualTrackUserMenuItem];
    
    NSMenuItem *textualStopTrackUserMenuItem = [[NSMenuItem alloc] init];
    [textualStopTrackUserMenuItem setTitle:@"Stop Tracking"];
    [textualStopTrackUserMenuItem setKeyEquivalent:NSStringEmptyPlaceholder];
    [textualStopTrackUserMenuItem setTarget:menuController()];
    [textualStopTrackUserMenuItem setAction:@selector(trackUserStopped:)];
    [textualStopTrackUserMenuItem setTag:424202];
    [userlistMenu addItem:textualStopTrackUserMenuItem];
    
    
    self.menuController.userControlMenu = userlistMenu;
    
}

- (void)didPostNewMessageForViewController:(TVCLogController *)logController
                               messageInfo:(NSDictionary *)messageInfo
                             isThemeReload:(BOOL)isThemeReload
                           isHistoryReload:(BOOL)isHistoryReload {
    
    IRCClient *clientFromMessage = [logController associatedClient];
    IRCChannel *channelFromMessage = [logController associatedChannel];
    NSString *senderNickNameFromMessage = [messageInfo stringForKey:@"senderNickname"];
    NSString *messageBodyFromMessage = [messageInfo stringForKey:@"messageBody"];
    
    BOOL isTextualSupportChannel = ([[channelFromMessage name] isEqualIgnoringCase:@"#textual"] || [[channelFromMessage name] isEqualIgnoringCase:@"#textual-unregistered"]);
    if([messageInfo integerForKey:@"lineType"] == TVCLogLinePrivateMessageType && isTextualSupportChannel) {
        BOOL userIsInTrackList = [userTrackList containsObject:senderNickNameFromMessage];
        if ([[messageInfo stringForKey:@"messageBody"] contains:@"?"] || userIsInTrackList) {
            BOOL userIsChannelRegular = [TPI_TextualSupportHelper userIsChannelRegular:[messageInfo stringForKey:@"senderNickname"] client:clientFromMessage channel:channelFromMessage];
            if (userIsChannelRegular) {
                return;
            }
            [self performBlockOnMainThread:^{
                TVCLogView *webView = [logController webView];
                WebScriptObject *executeJavaScript = [webView javaScriptAPI];
                [executeJavaScript callWebScriptMethod:@"supportMessageAtLine" withArguments:@[[messageInfo stringForKey:@"lineNumber"]]];
                
                if (isThemeReload == NO && isHistoryReload == NO) {
                    [clientFromMessage performSelector:@selector(setKeywordState:) withObject:channelFromMessage];
                    
                    [clientFromMessage notifyText:TXNotificationHighlightType
                                         lineType:[messageInfo integerForKey:@"lineType"]
                                           target:channelFromMessage
                                         nickname:senderNickNameFromMessage
                                             text:messageBodyFromMessage];
                }
            }];
        }
    } else {
    }
}

- (void)overrideExistingMenuItems {
    [[userlistMenu itemWithTag:504910] setAction:@selector(giveOperatorStatusToUser:)];
    [[userlistMenu itemWithTag:504912] setAction:@selector(giveVoiceStatusToUser:)];
    
    [[userlistMenu itemWithTag:504810] setAction:@selector(revokeOperatorStatusFromUser:)];
    [[userlistMenu itemWithTag:504812] setAction:@selector(revokeVoiceStatusFromUser:)];
    
    [[userlistMenu itemWithTitle:@"Ban"] setAction:@selector(banUserFromChannel:)];
    [[userlistMenu itemWithTitle:@"Kick"] setAction:@selector(kickUserFromChannel:)];
    [[userlistMenu itemWithTitle:@"Ban and Kick"] setAction:@selector(kickBanUserFromChannel:)];
}

@end
