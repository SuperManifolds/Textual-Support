#import "TPI_TextualSupport_MenuController.h"

@implementation TXMenuController (TPI_TextualSupport_MenuController)
- (void)postMenuMessage:(id)sender {
    IRCClient *u = [mainWindow() selectedClient];
    PointerIsEmptyAssert(u);
    for (IRCUser *m in [self selectedMembers:sender]) {
        [[u invokeOnMainThread] sendPrivmsgToSelectedChannel:[NSString stringWithFormat:@"%@, %@", m.nickname, [sender representedObject]]];
    }
    [self deselectMembers:sender];
}

- (void)postLinkToInputField:(id)sender {
    TVCMainWindowTextView *inputTextField = [mainWindow() inputTextField];
    LogToConsole(@"%@", [(NSMenuItem *)sender userInfo]);
    NSMutableAttributedString *newTextFieldValue = [[inputTextField attributedStringValue] mutableCopy];
    NSMutableAttributedString *linkFromDictionary = [[NSMutableAttributedString alloc] initWithString:[sender representedObject]
                                                                                  attributes:@{NSForegroundColorAttributeName: [inputTextField preferredFontColor]}];
    [newTextFieldValue appendAttributedString:linkFromDictionary];
    [inputTextField setAttributedStringValue:newTextFieldValue];
}

- (void)giveOperatorStatusToUser:(id)sender {
    IRCClient *u = [mainWindow() selectedClient];
    IRCChannel *c = [mainWindow() selectedChannel];
    PointerIsEmptyAssert(u);
    for (IRCUser *m in [self selectedMembers:sender]) {
        [[u invokeOnMainThread] sendCommand:[NSString stringWithFormat:@"CS OP %@ %@", [c name], m.nickname]];
    }
    [self deselectMembers:sender];
}

- (void)giveVoiceStatusToUser:(id)sender {
    IRCClient *u = [mainWindow() selectedClient];
    IRCChannel *c = [mainWindow() selectedChannel];
    PointerIsEmptyAssert(u);
    for (IRCUser *m in [self selectedMembers:sender]) {
        [[u invokeOnMainThread] sendCommand:[NSString stringWithFormat:@"CS VOICE %@ %@", [c name], m.nickname]];
    }
    [self deselectMembers:sender];
}

- (void)revokeOperatorStatusFromUser:(id)sender {
    IRCClient *u = [mainWindow() selectedClient];
    IRCChannel *c = [mainWindow() selectedChannel];
    PointerIsEmptyAssert(u);
    for (IRCUser *m in [self selectedMembers:sender]) {
        [[u invokeOnMainThread] sendCommand:[NSString stringWithFormat:@"CS DEOP %@ %@", [c name], m.nickname]];
    }
    [self deselectMembers:sender];
}

- (void)revokeVoiceStatusFromUser:(id)sender {
    IRCClient *u = [mainWindow() selectedClient];
    IRCChannel *c = [mainWindow() selectedChannel];
    PointerIsEmptyAssert(u);
    for (IRCUser *m in [self selectedMembers:sender]) {
        [[u invokeOnMainThread] sendCommand:[NSString stringWithFormat:@"CS DEVOICE %@ %@", [c name], m.nickname]];
    }
    [self deselectMembers:sender];
}

- (void)banUserFromChannel:(id)sender {
    IRCClient *u = [mainWindow() selectedClient];
    IRCChannel *c = [mainWindow() selectedChannel];
    PointerIsEmptyAssert(u);
    [u sendCommand:[NSString stringWithFormat:@"CS OP %@ %@", [c name], [u localNickname]]];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        for (IRCUser *m in [self selectedMembers:sender]) {
            [u sendCommand:[NSString stringWithFormat:@"%@ %@", IRCPublicCommandIndex("ban"), [m nickname]]
                                 completeTarget:YES
                                         target:[c name]];
        }
        [u sendCommand:[NSString stringWithFormat:@"CS DEOP %@ %@", [c name], [u localNickname]]];
        [self deselectMembers:sender];
    });
}

- (void)kickUserFromChannel:(id)sender {
    IRCClient *u = [mainWindow() selectedClient];
    IRCChannel *c = [mainWindow() selectedChannel];
    PointerIsEmptyAssert(u);
    [u sendCommand:[NSString stringWithFormat:@"CS OP %@ %@", [c name], [u localNickname]]];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        for (IRCUser *m in [self selectedMembers:sender]) {
            [u kick:c target:[m nickname]];
        }
        [u sendCommand:[NSString stringWithFormat:@"CS DEOP %@ %@", [c name], [u localNickname]]];
        [self deselectMembers:sender];
    });
}

- (void)kickBanUserFromChannel:(id)sender {
    IRCClient *u = [mainWindow() selectedClient];
    IRCChannel *c = [mainWindow() selectedChannel];
    PointerIsEmptyAssert(u);
    [u sendCommand:[NSString stringWithFormat:@"CS OP %@ %@", [c name], [u localNickname]]];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        for (IRCUser *m in [self selectedMembers:sender]) {
            [u sendCommand:[NSString stringWithFormat:@"%@ %@", IRCPublicCommandIndex("ban"), [m nickname]]
                                 completeTarget:YES
                                         target:[c name]];
            
            [u kick:c target:[m nickname]];
        }
        [u sendCommand:[NSString stringWithFormat:@"CS DEOP %@ %@", [c name], [u localNickname]]];
        [self deselectMembers:sender];
    });
}

- (void)trackUserInitiated:(id)sender {
    for (IRCUser *m in [self selectedMembers:sender]) {
        [TPI_TextualSupport.userTrackList addObject:[m nickname]];
    }
}

- (void)trackUserStopped:(id)sender {
    for (IRCUser *m in [self selectedMembers:sender]) {
        [TPI_TextualSupport.userTrackList removeObject:[m nickname]];
    }
}

/*- (BOOL)validateMenuItem:(NSMenuItem *)item {
    NSInteger menuItemTag = [item tag];
    switch (menuItemTag) {
        case 424201: {
            IRCChannel *c = [mainWindow() selectedChannel];
            if ([[c name] isEqualIgnoringCase:@"#textual"] == NO && [[c name] isEqualIgnoringCase:@"#textual-unregistered"] == NO) {
                [item setHidden:YES];
                return NO;
            }
            NSString *nameOfFirstSelectedUser = [[self selectedMembers:nil][0] nickname];
            BOOL userIsInTrackList = [TPI_TextualSupport.userTrackList containsObject:nameOfFirstSelectedUser];
            [item setHidden:userIsInTrackList];
            return YES;
        }
        case 424202: {
            IRCChannel *c = [mainWindow() selectedChannel];
            if ([[c name] isEqualIgnoringCase:@"#textual"] == NO && [[c name] isEqualIgnoringCase:@"#textual-unregistered"] == NO) {
                [item setHidden:YES];
                return NO;
            }
            NSString *nameOfFirstSelectedUser = [[self selectedMembers:nil][0] nickname];
            BOOL userIsInTrackList = [TPI_TextualSupport.userTrackList containsObject:nameOfFirstSelectedUser];
            [item setHidden:(userIsInTrackList == NO)];
            return YES;
        }
        default:
            return [[mainWindow() menuController] validateMenuItemTag:menuItemTag forItem:item];
    }
}*/

@end
