#import "TPI_TextualSupport_MenuController.h"

@implementation TXMenuController (TPI_TextualSupport_MenuController)

- (void)postMenuMessage:(id)sender {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            [selectedClient sendPrivmsg:[NSString stringWithFormat:@"%@, %@", selectedUser.nickname, [sender representedObject]] toChannel:selectedChannel];
        }
    }];
}

- (void)postLinkToInputField:(id)sender {
    TVCMainWindowTextView *inputTextField = [mainWindow() inputTextField];
    NSMutableAttributedString *newTextFieldValue = [[inputTextField attributedStringValue] mutableCopy];
    NSMutableAttributedString *linkFromDictionary = [[NSMutableAttributedString alloc] initWithString:[sender representedObject]
                                                                                  attributes:@{NSForegroundColorAttributeName: [inputTextField preferredFontColor]}];
    [newTextFieldValue appendAttributedString:linkFromDictionary];
    [inputTextField setAttributedStringValue:newTextFieldValue];
}

- (void)giveOperatorStatusToUser:(id)sender {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"CS OP %@ %@", [selectedChannel name], selectedUser.nickname]];
        }
    }];
}

- (void)giveVoiceStatusToUser:(id)sender {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"CS VOICE %@ %@", [selectedChannel name], selectedUser.nickname]];
        }
    }];
}

- (void)revokeOperatorStatusFromUser:(id)sender {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"CS DEOP %@ %@", [selectedChannel name], selectedUser.nickname]];
        }
    }];
}

- (void)revokeVoiceStatusFromUser:(id)sender {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"CS DEVOICE %@ %@", [selectedChannel name], selectedUser.nickname]];
        }
    }];
}

- (void)banUserFromChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"%@ %@", IRCPublicCommandIndex("ban"), [selectedUser nickname]]
                         completeTarget:YES
                                 target:[selectedChannel name]];
        }
    }];
}

- (void)unbanUserFromChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            IRCUser *realUser = [selectedChannel findMember:[selectedUser nickname]];
            NSArray *banList = [TPI_TextualSupport banListForChannel:[selectedChannel name] onClient:selectedClient];
            NSArray *matchingBans = [TPI_TextualSupportHelper listOfBansMatchingBanlist:banList withUser:realUser];
            for (NSString *ban in matchingBans) {
                [selectedClient sendCommand:[NSString stringWithFormat:@"MODE %@ -b %@", [selectedChannel name], ban]];
            }
        }
    }];
}

- (void)kickUserFromChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            [selectedClient kick:selectedChannel target:[selectedUser nickname]];
        }
    }];
}

- (void)kickBanUserFromChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"%@ %@", IRCPublicCommandIndex("ban"), [selectedUser nickname]]
            completeTarget:YES
                    target:[selectedChannel name]];
            
            [selectedClient kick:selectedChannel target:[selectedUser nickname]];
        }
    }];
}

- (void)muteUserOnChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            IRCUser *realUser = [selectedChannel findMember:[selectedUser nickname]];
            [selectedClient sendCommand:[NSString stringWithFormat:@"MODE %@ +q *!*@%@", [selectedChannel name], [realUser address]]];
        }
    }];
}

- (void)unmuteUserOnChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            IRCUser *realUser = [selectedChannel findMember:[selectedUser nickname]];
            NSArray *muteList = [TPI_TextualSupport muteListForChannel:[selectedChannel name] onClient:selectedClient];
            NSArray *matchingMutes = [TPI_TextualSupportHelper listOfBansMatchingBanlist:muteList withUser:realUser];
            for (NSString *mute in matchingMutes) {
                [selectedClient sendCommand:[NSString stringWithFormat:@"MODE %@ -q %@", [selectedChannel name], mute]];
            }
        }
    }];
}

- (void)performBlockOnSelectedUsers:(id)sender withBlock:(void (^)(IRCClient *, IRCChannel *, NSArray *))block {
    __strong IRCClient *selectedClient = [mainWindow() selectedClient];
    __strong IRCChannel *selectedChannel = [mainWindow() selectedChannel];
    PointerIsEmptyAssert(selectedClient);
    [self performBlockOnMainThread:^{
        block(selectedClient, selectedChannel, [self selectedMembers:sender]);
    }];
}

- (void)performBlockOnSelectedUsersAsChannelOperator:(id)sender withBlock:(void (^)(IRCClient *, IRCChannel *, NSArray *))block {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        IRCUser *localUser = [selectedChannel findMember:[selectedClient localNickname]];
        BOOL userHasExistingPrivilegies = [localUser isOp];
        
        if (userHasExistingPrivilegies == NO) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"CS OP %@ %@", [selectedChannel name], [selectedClient localNickname]]];
        }
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            block(selectedClient, selectedChannel, selectedUsers);
            if (userHasExistingPrivilegies == NO) {
                [selectedClient sendCommand:[NSString stringWithFormat:@"CS DEOP %@ %@", [selectedChannel name], [selectedClient localNickname]]];
            }
        });
    }];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    NSInteger menuItemTag = [item tag];
    IRCChannel *selectedChannel = [mainWindow() selectedChannel];
    IRCClient *selectedClient = [mainWindow() selectedClient];
    
    if (menuItemTag == 1511 || menuItemTag == 1513) {
        for (IRCUser *selectedUser in [self selectedMembers:item]) {
            IRCUser *realUser = [selectedChannel findMember:[selectedUser nickname]];
            NSArray *banList = [TPI_TextualSupport banListForChannel:[selectedChannel name] onClient:selectedClient];
            return [[TPI_TextualSupportHelper listOfBansMatchingBanlist:banList withUser:realUser] count] == 0;
        }
    }
    
    if (menuItemTag == 424201) {
        for (IRCUser *selectedUser in [self selectedMembers:item]) {
            IRCUser *realUser = [selectedChannel findMember:[selectedUser nickname]];
            NSArray *banList = [TPI_TextualSupport banListForChannel:[selectedChannel name] onClient:selectedClient];
            return [[TPI_TextualSupportHelper listOfBansMatchingBanlist:banList withUser:realUser] count] > 0;
        }
    }
    
    if (menuItemTag == 424202) {
        for (IRCUser *selectedUser in [self selectedMembers:item]) {
            IRCUser *realUser = [selectedChannel findMember:[selectedUser nickname]];
            NSArray *muteList = [TPI_TextualSupport muteListForChannel:[selectedChannel name] onClient:selectedClient];
            return [[TPI_TextualSupportHelper listOfBansMatchingBanlist:muteList withUser:realUser] count] == 0;
        }
    }
    
    if (menuItemTag == 424203) {
        for (IRCUser *selectedUser in [self selectedMembers:item]) {
            IRCUser *realUser = [selectedChannel findMember:[selectedUser nickname]];
            NSArray *muteList = [TPI_TextualSupport muteListForChannel:[selectedChannel name] onClient:selectedClient];
            return [[TPI_TextualSupportHelper listOfBansMatchingBanlist:muteList withUser:realUser] count] > 0;
        }
    }
    
    return [menuController() validateMenuItemTag:menuItemTag forItem:item];
}

@end
