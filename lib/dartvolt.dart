// https://revolt.chat API Wrapper for dart.
// Copyright (C) 2021 janderedev

library dartvolt;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:eventify/eventify.dart';

part 'src/misc/EventHandler.dart';
part 'src/misc/logger.dart';

part 'src/Client.dart';

part 'src/structs/AuthData.dart';
part 'src/structs/ClientConfig.dart';
part 'src/structs/ServerConfig.dart';
part 'src/structs/Channel.dart';
part 'src/structs/User.dart';
part 'src/structs/ChannelManager.dart';
part 'src/structs/UserManager.dart';

part 'src/websocket/Client.dart';