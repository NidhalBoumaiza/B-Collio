// lib/screens/chat/ChatRoom/call_page.dart
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import '../../../controllers/call_service_controller.dart';
import 'package:get/get.dart';

class CallPage extends StatefulWidget {
  final String localUserID;
  final String localUserName;
  final String targetUserID;
  final String targetUserName;
  final String roomID;
  final bool isVideoCall;

  const CallPage({
    super.key,
    required this.localUserID,
    required this.localUserName,
    required this.targetUserID,
    required this.targetUserName,
    required this.roomID,
    required this.isVideoCall,
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  Widget? localView;
  int? localViewID;
  Widget? remoteView;
  int? remoteViewID;
  final CallServiceController callController = Get.find<CallServiceController>();

  @override
  void initState() {
    super.initState();
    startListenEvent();
    loginRoom();
  }

  @override
  void dispose() {
    stopListenEvent();
    logoutRoom();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.isVideoCall ? 'Video' : 'Voice'} Call with ${widget.targetUserName}")),
      body: Stack(
        children: [
          localView ?? const SizedBox.shrink(),
          Positioned(
            top: MediaQuery.of(context).size.height / 20,
            right: MediaQuery.of(context).size.width / 20,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              child: AspectRatio(
                aspectRatio: 9.0 / 16.0,
                child: remoteView ?? Container(color: Colors.black.withOpacity(0.2)),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 20,
            left: 0,
            right: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 3,
              height: MediaQuery.of(context).size.width / 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context),
                    child: const Center(child: Icon(Icons.call_end, size: 32)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> loginRoom() async {
    final user = ZegoUser(widget.localUserID, widget.localUserName);
    ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig()..isUserStatusNotify = true;

    await ZegoExpressEngine.instance
        .loginRoom(widget.roomID, user, config: roomConfig)
        .then((result) {
      if (result.errorCode == 0) {
        startPreview();
        startPublish();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${result.errorCode}')),
        );
      }
    });
  }

  Future<void> logoutRoom() async {
    stopPreview();
    stopPublish();
    await ZegoExpressEngine.instance.logoutRoom(widget.roomID);
  }

  void startListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate = callController.onRoomUserUpdate;
    ZegoExpressEngine.onRoomStreamUpdate = (roomID, updateType, List<ZegoStream> streamList, extendedData) {
      if (updateType == ZegoUpdateType.Add) {
        for (final stream in streamList) {
          startPlayStream(stream.streamID);
        }
      } else {
        for (final stream in streamList) {
          stopPlayStream(stream.streamID);
        }
      }
    };
    ZegoExpressEngine.onRoomStateUpdate = (roomID, state, errorCode, extendedData) {
      debugPrint('onRoomStateUpdate: $roomID, $state, $errorCode');
    };
    ZegoExpressEngine.onPublisherStateUpdate = (streamID, state, errorCode, extendedData) {
      debugPrint('onPublisherStateUpdate: $streamID, $state, $errorCode');
    };
  }

  void stopListenEvent() {
    ZegoExpressEngine.onRoomUserUpdate = null;
    ZegoExpressEngine.onRoomStreamUpdate = null;
    ZegoExpressEngine.onRoomStateUpdate = null;
    ZegoExpressEngine.onPublisherStateUpdate = null;
  }

  Future<void> startPreview() async {
    await ZegoExpressEngine.instance.createCanvasView((viewID) {
      localViewID = viewID;
      ZegoCanvas previewCanvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPreview(canvas: previewCanvas, channel: ZegoPublishChannel.Main);
    }).then((canvasViewWidget) {
      setState(() => localView = canvasViewWidget);
    });
    if (!widget.isVideoCall) {
      ZegoExpressEngine.instance.mutePublishStreamVideo(true, channel: ZegoPublishChannel.Main);
    }
  }

  Future<void> stopPreview() async {
    ZegoExpressEngine.instance.stopPreview(channel: ZegoPublishChannel.Main);
    if (localViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(localViewID!);
      if (mounted) setState(() => localView = null);
    }
  }

  Future<void> startPublish() async {
    String streamID = '${widget.roomID}_${widget.localUserID}_call';
    await ZegoExpressEngine.instance.startPublishingStream(streamID, channel: ZegoPublishChannel.Main);
    if (callController.incomingCallData != null && callController.incomingCallData!['conversation_id'] == widget.roomID) {
      callController.incomingCallData!['is_video_call'] = widget.isVideoCall;
    }
  }

  Future<void> stopPublish() async {
    await ZegoExpressEngine.instance.stopPublishingStream(channel: ZegoPublishChannel.Main);
  }

  Future<void> startPlayStream(String streamID) async {
    await ZegoExpressEngine.instance.createCanvasView((viewID) {
      remoteViewID = viewID;
      ZegoCanvas canvas = ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill);
      ZegoExpressEngine.instance.startPlayingStream(streamID, canvas: canvas);
    }).then((canvasViewWidget) {
      setState(() => remoteView = canvasViewWidget);
    });
    if (!widget.isVideoCall) {
      ZegoExpressEngine.instance.mutePlayStreamVideo(streamID, true);
    }
  }

  Future<void> stopPlayStream(String streamID) async {
    ZegoExpressEngine.instance.stopPlayingStream(streamID);
    if (remoteViewID != null) {
      await ZegoExpressEngine.instance.destroyCanvasView(remoteViewID!);
      if (mounted) setState(() => remoteView = null);
    }
  }
}