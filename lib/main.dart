// https://revolt.chat API Wrapper for dart.
// Copyright (C) 2021  janderedev

library dartvolt;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as WSStatus;

part 'src/Client.dart';

part 'src/structs/SessionInfo.dart';
part 'src/structs/ClientConfig.dart';
part 'src/structs/ServerConfig.dart';

part 'src/websocket/Client.dart';