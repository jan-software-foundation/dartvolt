part of dartvolt;

class RolePermissions {
    Client client;
    
    BasePermissions channelPermissions;
    BasePermissions serverPermissions;
    
    RolePermissions(this.client, {
        required this.serverPermissions,
        required this.channelPermissions,
    });
}

class BasePermissions {
    int bitfield;
    Map<String, int> permissionList;
    
    /// Checks if this Object has a specific permission
    bool has(String permission) {
        var permissionBit = permissionList[permission];
        if (permissionBit == null) throw 'Unknown permission: $permission';
        // Good lord I spent hours trying to figure out how this works
        return bitfield & permissionBit != 0;
    }
    
    BasePermissions(this.bitfield, this.permissionList);
}

// https://gitlab.insrt.uk/revolt/revolt.js/-/blob/master/src/api/permissions.ts

/// Available permission keys: \
/// `Access`, `ViewProfile`, `SendMessage`, `Invite`
const UserPermissions = {
    'Access':       1,
    'ViewProfile':  2,
    'SendMessage':  4,
    'Invite':       8,
};

/// Available permission keys: \
/// `View`, `SendMessage`, `ManageMessages`, `ManageChannel`,
/// `VoiceCall`, `InviteOthers`, `EmbedLinks`, `UploadFiles`
const ChannelPermissions = {
    'View':             1,
    'SendMessage':      2,
    'ManageMessages':   4,
    'ManageChannel':    8,
    'VoiceCall':        16,
    'InviteOthers':     32,
    'EmbedLinks':       64,
    'UploadFiles':      128,
};

/// Available permission keys: \
/// `View`, `ManageRoles`, `ManageChannels`, `ManageServer`,
/// `KickMembers`, `BanMembers`, `ChangeNickname`, `ManageNicknames`,
/// `ChangeAvatar`, `RemoveAvatars`
const ServerPermissions = {
    'View':             1,
    'ManageRoles':      2,
    'ManageChannels':   4,
    'ManageServer':     8,
    'KickMembers':      16,
    'BanMembers':       32,
    'ChangeNickname':   4096,
    'ManageNicknames':  8192,
    'ChangeAvatar':     16384,
    'RemoveAvatars':    32768,
};
