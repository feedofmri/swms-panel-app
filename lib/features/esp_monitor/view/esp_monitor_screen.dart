import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/models/esp_serial_data.dart';
import '../../../core/utils/app_theme.dart';

class EspMonitorScreen extends StatefulWidget {
  const EspMonitorScreen({super.key});

  @override
  State<EspMonitorScreen> createState() => _EspMonitorScreenState();
}

class _EspMonitorScreenState extends State<EspMonitorScreen> {
  final TextEditingController _ipController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<EspSerialData> _messages = [];
  bool _autoScroll = true;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _ipController.text = '192.168.1.114'; // Default IP from your ESP code
  }

  @override
  void dispose() {
    _ipController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('ESP8266 Monitor'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
            tooltip: _isPaused ? 'Resume' : 'Pause',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearMessages,
            tooltip: 'Clear Messages',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Panel
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESP8266 Connection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ipController,
                        decoration: InputDecoration(
                          labelText: 'ESP8266 IP Address',
                          hintText: '192.168.1.114',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.wifi),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Consumer<WebSocketService>(
                      builder: (context, wsService, child) {
                        return ElevatedButton.icon(
                          onPressed: wsService.isConnecting
                              ? null
                              : () {
                                  if (wsService.isConnected) {
                                    wsService.disconnect();
                                  } else {
                                    wsService.connect(_ipController.text.trim());
                                  }
                                },
                          icon: Icon(
                            wsService.isConnected
                                ? Icons.link_off
                                : Icons.link,
                          ),
                          label: Text(
                            wsService.isConnected
                                ? 'Disconnect'
                                : wsService.isConnecting
                                    ? 'Connecting...'
                                    : 'Connect',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: wsService.isConnected
                                ? AppTheme.errorColor
                                : AppTheme.primaryColor,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Consumer<WebSocketService>(
                  builder: (context, wsService, child) {
                    return Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: wsService.isConnected
                                ? Colors.green
                                : wsService.isConnecting
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          wsService.connectionStatus,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Controls Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Checkbox(
                      value: _autoScroll,
                      onChanged: (value) {
                        setState(() {
                          _autoScroll = value ?? true;
                        });
                      },
                    ),
                    const Text(
                      'Auto-scroll',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Consumer<WebSocketService>(
                builder: (context, wsService, child) {
                  return StreamBuilder<EspSerialData>(
                    stream: wsService.espSerialDataStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && !_isPaused) {
                        _messages.add(snapshot.data!);
                        // Keep only last 1000 messages to prevent memory issues
                        if (_messages.length > 1000) {
                          _messages.removeAt(0);
                        }
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });
                      }

                      if (_messages.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.message_outlined,
                                size: 64,
                                color: AppTheme.textSecondary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Connect to your ESP8266 to see serial data',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageTile(message);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(EspSerialData message) {
    final timeStr = '${message.timestamp.hour.toString().padLeft(2, '0')}:'
        '${message.timestamp.minute.toString().padLeft(2, '0')}:'
        '${message.timestamp.second.toString().padLeft(2, '0')}';

    Color borderColor = Colors.grey.shade300;
    Color backgroundColor = Colors.transparent;

    switch (message.dataType) {
      case EspDataType.error:
        borderColor = AppTheme.errorColor.withOpacity(0.5);
        backgroundColor = AppTheme.errorColor.withOpacity(0.1);
        break;
      case EspDataType.status:
        borderColor = Colors.green.withOpacity(0.5);
        backgroundColor = Colors.green.withOpacity(0.1);
        break;
      case EspDataType.sensorReading:
        borderColor = AppTheme.primaryColor.withOpacity(0.5);
        backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
        break;
      case EspDataType.control:
        borderColor = Colors.orange.withOpacity(0.5);
        backgroundColor = Colors.orange.withOpacity(0.1);
        break;
      default:
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                message.dataType.icon,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                message.dataType.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.rawMessage,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
              fontFamily: 'monospace',
            ),
          ),
          if (message.hasNumericData) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: message.numericValues.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
