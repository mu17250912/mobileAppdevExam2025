# SkillSwap Messaging System

## Overview
The SkillSwap messaging system provides a complete real-time chat functionality with the following features:

- **Real-time messaging** with typing indicators
- **Message status tracking** (sent, delivered, read, failed)
- **Conversation management** with unread message counts
- **Push notifications** for new messages
- **Session requests** integration
- **Message history** and conversation persistence

## Architecture

### Models
1. **Message Model** (`lib/models/message_model.dart`)
   - Handles individual message data
   - Supports different message types (text, image, file, sessionRequest)
   - Tracks message status and metadata

2. **ChatConversation Model** (`lib/models/chat_conversation_model.dart`)
   - Manages conversation metadata
   - Tracks unread message counts per participant
   - Handles conversation state (active/inactive)

### Services
**MessagingService** (`lib/services/messaging_service.dart`)
- Singleton service for all messaging operations
- Handles message sending, receiving, and status updates
- Manages conversation creation and updates
- Provides typing indicator functionality
- Handles unread message counting

### Screens
1. **ChatListScreen** (`lib/screens/chat_list_screen.dart`)
   - Displays all user conversations
   - Shows unread message badges
   - Provides conversation management options

2. **ChatScreen** (`lib/screens/chat_screen.dart`)
   - Individual conversation interface
   - Real-time message streaming
   - Typing indicators
   - Message status display

## Firestore Collections

### 1. Messages Collection
```javascript
{
  senderId: string,
  receiverId: string,
  content: string,
  type: "text" | "image" | "file" | "sessionRequest",
  status: "sent" | "delivered" | "read" | "failed",
  timestamp: timestamp,
  metadata: object (optional),
  replyToMessageId: string (optional),
  attachments: string[] (optional)
}
```

### 2. Conversations Collection
```javascript
{
  participants: string[],
  lastMessageId: string,
  lastMessageContent: string,
  lastMessageSenderId: string,
  lastMessageTime: timestamp,
  unreadCount: number,
  participantUnreadCounts: { [userId]: number },
  isActive: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 3. Typing Collection
```javascript
{
  isTyping: boolean,
  userId: string,
  timestamp: timestamp
}
```

## Features

### Real-time Messaging
- Messages are sent and received in real-time using Firestore streams
- Automatic message status updates (sent → delivered → read)
- Message persistence and history

### Typing Indicators
- Real-time typing status updates
- Automatic cleanup of typing indicators
- Visual feedback in chat interface

### Message Status
- **Sent**: Message created and stored
- **Delivered**: Message successfully delivered to recipient
- **Read**: Message has been read by recipient
- **Failed**: Message delivery failed

### Unread Message Counts
- Per-conversation unread message tracking
- Global unread count for home screen badge
- Automatic marking as read when opening conversations

### Conversation Management
- Soft delete conversations (set isActive to false)
- Long-press options for conversation actions
- Conversation metadata updates

### Push Notifications
- Automatic notification creation for new messages
- Rich notification content with sender information
- Deep linking to specific conversations

## Security Rules

The Firestore security rules ensure:
- Users can only read messages they're involved in
- Users can only send messages as themselves
- Message status can only be updated by the sender
- Conversations can only be accessed by participants
- Typing indicators are user-specific

## Usage Examples

### Sending a Message
```dart
final messagingService = MessagingService();
await messagingService.sendMessage(
  receiverId: 'user123',
  content: 'Hello! How are you?',
);
```

### Getting Messages Stream
```dart
Stream<List<Message>> messages = messagingService.getMessages('user123');
```

### Getting Conversations
```dart
Stream<List<ChatConversation>> conversations = messagingService.getUserConversations();
```

### Marking Messages as Read
```dart
await messagingService.markMessagesAsRead('user123');
```

### Getting Unread Count
```dart
Stream<int> unreadCount = messagingService.getUnreadMessageCount();
```

## Setup Instructions

1. **Deploy Firestore Rules**
   - Copy the contents of `firestore_rules_messaging.txt`
   - Deploy to your Firestore project

2. **Deploy Firestore Indexes**
   - Copy the contents of `firestore_indexes_messaging.json`
   - Deploy to your Firestore project

3. **Update Dependencies**
   - Ensure all required packages are in `pubspec.yaml`

4. **Initialize Messaging Service**
   - The service is automatically initialized when used
   - No additional setup required

## Troubleshooting

### Common Issues

1. **Messages not appearing**
   - Check Firestore rules
   - Verify user authentication
   - Check network connectivity

2. **Typing indicators not working**
   - Ensure typing collection rules are deployed
   - Check user permissions

3. **Unread counts not updating**
   - Verify conversation document structure
   - Check participantUnreadCounts field

4. **Push notifications not working**
   - Verify FCM setup
   - Check notification collection rules
   - Ensure user has FCM token

### Debug Mode
Enable debug logging by adding:
```dart
debugPrint('Messaging Debug: $message');
```

## Performance Considerations

- Messages are paginated and loaded on-demand
- Conversations are cached locally
- Typing indicators have automatic cleanup
- Unread counts are calculated efficiently using Firestore queries

## Future Enhancements

- Message encryption
- File/image sharing
- Voice messages
- Message reactions
- Group conversations
- Message search
- Message deletion
- Message forwarding 