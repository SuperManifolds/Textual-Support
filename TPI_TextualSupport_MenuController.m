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
            [selectedClient sendCommand:[NSString stringWithFormat:@"MODE %@ -b *!*%@", [selectedChannel name], [selectedUser hostmask]]];
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
            NSLog(@"address: %@", [realUser address]);
            [selectedClient sendCommand:[NSString stringWithFormat:@"MODE %@ +q *!*@%@", [selectedChannel name], [realUser address]]];
        }
    }];
}

- (void)unmuteUserOnChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel, NSArray *selectedUsers){
        for (IRCUser *selectedUser in selectedUsers) {
            IRCUser *realUser = [selectedChannel findMember:[selectedUser nickname]];
            NSArray *muteList = [TPI_TextualSupport muteListForChannel:[selectedClient name] onClient:selectedClient];
            NSLog(@"matching: %@", [TPI_TextualSupportHelper listOfBansMatchingBanlist:muteList withUser:realUser]);
            [selectedClient sendCommand:[NSString stringWithFormat:@"MODE %@ -q *!*@%@", [selectedChannel name], [realUser address]]];
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
        [selectedClient sendCommand:[NSString stringWithFormat:@"CS OP %@ %@", [selectedChannel name], [selectedClient localNickname]]];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            block(selectedClient, selectedChannel, selectedUsers);
            [selectedClient sendCommand:[NSString stringWithFormat:@"CS DEOP %@ %@", [selectedChannel name], [selectedClient localNickname]]];
        });
    }];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    NSInteger menuItemTag = [item tag];
    return [[mainWindow() menuController] validateMenuItemTag:menuItemTag forItem:item];
}

@end
