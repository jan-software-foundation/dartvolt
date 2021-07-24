// https://revolt.chat API Wrapper for dart.
// Copyright (C) 2021 janderedev

library dartvolt;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:eventify/eventify.dart';

part 'src/Client.dart';

part 'src/misc/EventHandler.dart';
part 'src/misc/logger.dart';
part 'src/misc/Utilities.dart';

part 'src/structs/AuthData.dart';
part 'src/structs/ClientConfig.dart';
part 'src/structs/ServerConfig.dart';
part 'src/structs/Channel.dart';
part 'src/structs/User.dart';
part 'src/structs/File.dart';
part 'src/structs/Message.dart';
part 'src/structs/Managers/ChannelManager.dart';
part 'src/structs/Managers/UserManager.dart';
part 'src/structs/Managers/MessageManager.dart';
part 'src/structs/Managers/ServerManager.dart';
part 'src/structs/Managers/ServerMemberManager.dart';
part 'src/structs/Servers/Server.dart';
part 'src/structs/Servers/Member.dart';
part 'src/structs/Servers/Category.dart';
part 'src/structs/Servers/Role.dart';
part 'src/structs/Servers/Permissions.dart';

part 'src/websocket/Client.dart';