#include "TPI_TextualSupport.h"

@interface TXMenuController (TPI_TextualSupport_MenuController)
- (void)postMenuMessage:(id)sender;
- (void)postLinkToInputField:(id)sender;

- (void)giveOperatorStatusToUser:(id)sender;
- (void)giveVoiceStatusToUser:(id)sender;
- (void)revokeOperatorStatusFromUser:(id)sender;
- (void)revokeVoiceStatusFromUser:(id)sender;

- (void)banUserFromChannel:(id)sender;
- (void)kickUserFromChannel:(id)sender;
- (void)kickBanUserFromChannel:(id)sender;

@end
