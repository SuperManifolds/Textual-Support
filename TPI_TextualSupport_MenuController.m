#import "TPI_TextualSupport_MenuController.h"

@implementation TXMenuController (TPI_TextualSupport_MenuController)
- (void)postMenuMessage:(id)sender {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
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
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"CS OP %@ %@", [selectedChannel name], selectedUser.nickname]];
        }
    }];
}

- (void)giveVoiceStatusToUser:(id)sender {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
            [self performBlockOnMainThread:^{
                [selectedClient sendCommand:[NSString stringWithFormat:@"CS VOICE %@ %@", [selectedChannel name], selectedUser.nickname]];
            }];
        }
    }];
}

- (void)revokeOperatorStatusFromUser:(id)sender {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"CS DEOP %@ %@", [selectedChannel name], selectedUser.nickname]];
        }
    }];
}

- (void)revokeVoiceStatusFromUser:(id)sender {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"CS DEVOICE %@ %@", [selectedChannel name], selectedUser.nickname]];
        }
    }];
}

- (void)banUserFromChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"%@ %@", IRCPublicCommandIndex("ban"), [selectedUser nickname]]
                         completeTarget:YES
                                 target:[selectedChannel name]];
        }
    }];
}

- (void)unbanUserFromChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"MODE %@ -b *!*%@", [selectedChannel name], [selectedUser hostmask]]];
        }
    }];
}

- (void)kickUserFromChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
            [selectedClient kick:selectedChannel target:[selectedUser nickname]];
        }
    }];
}

- (void)kickBanUserFromChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"%@ %@", IRCPublicCommandIndex("ban"), [selectedUser nickname]]
            completeTarget:YES
                    target:[selectedChannel name]];
            
            [selectedClient kick:selectedChannel target:[selectedUser nickname]];
        }
    }];
}

- (void)muteUserOnChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"MODE %@ +q *!*%@", [selectedChannel name], [selectedUser hostmask]]];
        }
    }];
}

- (void)unmuteUserOnChannel:(id)sender {
    [self performBlockOnSelectedUsersAsChannelOperator:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        for (IRCUser *selectedUser in [self selectedMembers:sender]) {
            [selectedClient sendCommand:[NSString stringWithFormat:@"MODE %@ -q *!*%@", [selectedChannel name], [selectedUser hostmask]]];
        }
    }];
}

- (void)performBlockOnSelectedUsers:(id)sender withBlock:(void (^)(IRCClient *, IRCChannel *))block {
    IRCClient *selectedClient = [mainWindow() selectedClient];
    IRCChannel *selectedChannel = [mainWindow() selectedChannel];
    PointerIsEmptyAssert(selectedClient);
    [self performBlockOnMainThread:^{
        block(selectedClient, selectedChannel);
    }];
    [self deselectMembers:sender];
}

- (void)performBlockOnSelectedUsersAsChannelOperator:(id)sender withBlock:(void (^)(IRCClient *, IRCChannel *))block {
    [self performBlockOnSelectedUsers:sender withBlock:^(IRCClient *selectedClient, IRCChannel *selectedChannel){
        [selectedClient sendCommand:[NSString stringWithFormat:@"CS OP %@ %@", [selectedChannel name], [selectedClient localNickname]]];
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            block(selectedClient, selectedChannel);
            [selectedClient sendCommand:[NSString stringWithFormat:@"CS DEOP %@ %@", [selectedChannel name], [selectedClient localNickname]]];
        });
    }];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    NSInteger menuItemTag = [item tag];
    return [[mainWindow() menuController] validateMenuItemTag:menuItemTag forItem:item];
}

@end
