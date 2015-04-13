#import "TPI_TextualSupport.h"
#import "TPI_TextualSupport_MenuController.h"
#import "TPI_TextualSupportHelper.h"

@implementation TPI_TextualSupport

NSMenu *userlistMenu;
NSMenu *inputFieldMenu;
NSDictionary *messageCacheForSupportChannel;
NSMutableDictionary *serverSoftwareList;
BOOL isReceivingBanMessages;
BOOL isReceivingMuteMessages;


static NSMutableDictionary *banList;
static NSMutableDictionary *muteList;

-  (NSArray *)subscribedServerInputCommands {
    return @[@"join", @"part", @"004", @"728", @"729", @"367", @"368"];
}

- (NSArray *)serverSoftwareWithMuteSupport {
    return @[@"irc-seven", @"inspircd"];
}


- (void)pluginLoadedIntoMemory {
	userlistMenu = self.menuController.userControlMenu;
    inputFieldMenu = [[mainWindow() inputTextField] menu];
    serverSoftwareList = [[NSMutableDictionary alloc] init];
    banList = [[NSMutableDictionary alloc] init];
    muteList = [[NSMutableDictionary alloc] init];
    
    [self overrideExistingMenuItems];
    
    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource: @"messages" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    
    NSMenuItem *textualSupportMenuItems = [[NSMenuItem alloc] init];
	[textualSupportMenuItems setTitle:@"Textual Support"];
	[textualSupportMenuItems setKeyEquivalent:@""];
    NSMenu *textualSupportMenu = [NSMenu new];
	[textualSupportMenu setTitle:@"Textual Support"];
    NSArray *supportMessages = dict[@"userlist"];
    [TPI_TextualSupportHelper addItemsFromArrayToMenu:textualSupportMenu menuItems:supportMessages selector:@selector(postMenuMessage:)];
    [textualSupportMenuItems setSubmenu: textualSupportMenu];
	[userlistMenu addItem:[textualSupportMenuItems copy]];
    
    NSMenuItem *textualInsertLinksMenuItems = [[NSMenuItem alloc] init];
    [textualInsertLinksMenuItems setTitle:@"Insert Support Link"];
    [textualInsertLinksMenuItems setKeyEquivalent:@""];
    NSMenu *textualInsertLinksMenu = [NSMenu new];
    [textualInsertLinksMenuItems setTitle:@"Insert Support Link"];
    NSArray *insertLinkMessages = dict[@"insertlink"];
    [TPI_TextualSupportHelper addItemsFromArrayToMenu:textualInsertLinksMenu menuItems:insertLinkMessages selector:@selector(postLinkToInputField:)];
    [textualInsertLinksMenuItems setSubmenu:textualInsertLinksMenu];
    [inputFieldMenu addItem:[textualInsertLinksMenuItems copy]];
    
    NSInteger indexOfBanItem = [userlistMenu indexOfItemWithTitle:@"Ban"];
    
    NSMenuItem *textualUnbanUserMenuItem = [[NSMenuItem alloc] init];
    [textualUnbanUserMenuItem setTitle:@"Unban"];
    [textualUnbanUserMenuItem setKeyEquivalent:@""];
    [textualUnbanUserMenuItem setTarget:menuController()];
    [textualUnbanUserMenuItem setAction:@selector(unmuteUserOnChannel:)];
    [textualUnbanUserMenuItem setTag:424201];
    [userlistMenu insertItem:textualUnbanUserMenuItem atIndex:(indexOfBanItem + 1)];
    
    NSMenuItem *textualMuteUserMenuItem = [[NSMenuItem alloc] init];
    [textualMuteUserMenuItem setTitle:@"Mute"];
    [textualMuteUserMenuItem setKeyEquivalent:@""];
    [textualMuteUserMenuItem setTarget:menuController()];
    [textualMuteUserMenuItem setAction:@selector(muteUserOnChannel:)];
    [textualMuteUserMenuItem setTag:424202];
    [userlistMenu insertItem:textualMuteUserMenuItem atIndex:(indexOfBanItem + 2)];
    
    
    NSMenuItem *textualUnmuteUserMenuItem = [[NSMenuItem alloc] init];
    [textualUnmuteUserMenuItem setTitle:@"Unmute"];
    [textualUnmuteUserMenuItem setKeyEquivalent:@""];
    [textualUnmuteUserMenuItem setTarget:menuController()];
    [textualUnmuteUserMenuItem setAction:@selector(unmuteUserOnChannel:)];
    [userlistMenu insertItem:textualUnmuteUserMenuItem atIndex:(indexOfBanItem + 3)];
    
    self.menuController.userControlMenu = userlistMenu;
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

- (void)didReceiveServerInputOnClient:(IRCClient *)client
                    senderInformation:(NSDictionary *)senderDict
                   messageInformation:(NSDictionary *)messageDict {
    
    NSString *command = [messageDict objectForKey:THOPluginProtocolDidReceiveServerInputMessageCommandAttribute];
    
    if ([command isEqualToString:@"004"]) {
        NSString *serverSoftware = [messageDict objectForKey:THOPluginProtocolDidReceiveServerInputMessageSequenceAttribute];
        [serverSoftwareList setObject:serverSoftware forKey:[client uniqueIdentifier]];
    }
    
    else if ([command isEqualToString:@"JOIN"]) {
        NSString *sender = [senderDict objectForKey:THOPluginProtocolDidReceiveServerInputSenderNicknameAttribute];
        NSString *channel = [messageDict objectForKey:THOPluginProtocolDidReceiveServerInputMessageParamatersAttribute][0];
        
        if ([sender isEqualIgnoringCase:[client localNickname]] == NO) return;
        
        if ([banList objectForKey:[client uniqueIdentifier]] == nil) {
            [banList setObject:[[NSMutableDictionary alloc] init] forKey:[client uniqueIdentifier]];
        }
        
        if ([muteList objectForKey:[client uniqueIdentifier]] == nil) {
            [muteList setObject:[[NSMutableDictionary alloc] init] forKey:[client uniqueIdentifier]];
        }
        
        [client sendCommand:[NSString stringWithFormat:@"MODE %@ +b", channel]];
        if ([self serverSupportsMute:client]) {
            [client sendCommand:[NSString stringWithFormat:@"MODE %@ +q", channel]];
        }
    } else if ([command isEqualToString:@"367"]) {
        NSArray *parameters = [messageDict objectForKey:THOPluginProtocolDidReceiveServerInputMessageParamatersAttribute];
        NSString *channel = parameters[1];
        NSMutableDictionary *banChannels = [banList objectForKey:[client uniqueIdentifier]];
        
        if (isReceivingBanMessages == NO) {
            [banChannels setObject:[[NSMutableArray alloc] init] forKey:channel];
            isReceivingBanMessages = YES;
        }
        
        NSMutableArray *bans = [banChannels objectForKey:channel];
        [bans addObject:parameters[2]];
        [banChannels setObject:bans forKey:channel];
        [banList setObject:banChannels forKey:[client uniqueIdentifier]];
    } else if ([command isEqualToString:@"368"]) {
        isReceivingBanMessages = NO;
    } else if ([command isEqualToString:@"728"]) {
        NSArray *parameters = [messageDict objectForKey:THOPluginProtocolDidReceiveServerInputMessageParamatersAttribute];
        NSString *channel = parameters[1];
        NSMutableDictionary *muteChannels = [muteList objectForKey:[client uniqueIdentifier]];
        
        if (isReceivingMuteMessages == NO) {
            [muteChannels setObject:[[NSMutableArray alloc] init] forKey:channel];
            isReceivingMuteMessages = YES;
        }
        
        NSMutableArray *mutes = [muteChannels objectForKey:channel];
        [mutes addObject:parameters[2]];
        [muteChannels setObject:mutes forKey:channel];
        
        [muteList setObject:muteChannels forKey:[client uniqueIdentifier]];
    } else if ([command isEqualToString:@"729"]) {
        isReceivingMuteMessages = NO;
    }
}

- (BOOL)serverSupportsMute:(IRCClient *)client {
    NSString *currentServerSoftware = [serverSoftwareList objectForKey:[client uniqueIdentifier]];
    for (NSString *serverSoftware in self.serverSoftwareWithMuteSupport) {
        if ([serverSoftware containsIgnoringCase:currentServerSoftware]) return YES;
    }
    return YES;
}


+ (NSMutableArray *)banListForChannel:(NSString *)channel onClient:(IRCClient *)client {
    NSMutableDictionary *channels = [banList objectForKey:[client uniqueIdentifier]];
    return [channels objectForKey:channel];
}

+ (NSMutableArray *)muteListForChannel:(NSString *)channel onClient:(IRCClient *)client {
    NSLog(@"mute list: %@", muteList);
    NSMutableDictionary *channels = [muteList objectForKey:[client uniqueIdentifier]];
    return [channels objectForKey:channel];
}

@end
