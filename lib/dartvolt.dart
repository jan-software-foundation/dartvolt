// https://revolt.chat API Wrapper for dart.
// Copyright (C) 2021 janderedev

library dartvolt;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

part 'src/Client.dart';
part 'src/Logger.dart';

part 'src/websocket/WSClient.dart';
part 'src/websocket/EventHandler.dart';

part 'src/structs/ServerConfig.dart';

part 'src/structs/user/User.dart';
