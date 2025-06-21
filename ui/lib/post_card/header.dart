import 'package:flutter/material.dart';

class PostCardHeader extends StatelessWidget {
  final Function()? onOpenProfileInBrowserPressed;
  final Function()? onCopyPressed;
  final Function()? onSharePressed;
  final Function()? onOpenPostInBrowserPressed;
  final String displayName;
  final String handle;
  final String? avatarUrl;

  const PostCardHeader({
    super.key,
    required this.displayName,
    required this.handle,
    this.avatarUrl,
    this.onOpenProfileInBrowserPressed,
    this.onCopyPressed,
    this.onSharePressed,
    this.onOpenPostInBrowserPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Header row
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
              // Display name and handle
              child: InkWell(
                  onTap: onOpenProfileInBrowserPressed,
                  borderRadius: BorderRadius.all(Radius.circular(8.0)),
                  child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Flexible(
                            flex: 1,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Display name
                                  Text(
                                    displayName,
                                    style: const TextStyle(fontSize: 16.0),
                                    overflow: TextOverflow.fade,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                  // Handle
                                  Text(
                                    handle,
                                    style: const TextStyle(fontSize: 12.0),
                                    overflow: TextOverflow.fade,
                                    maxLines: 1,
                                    softWrap: false,
                                  )
                                ]))
                      ])))),
          PostCardButtons(
              onCopyPressed: onCopyPressed,
              onSharePressed: onSharePressed,
              onOpenInBrowserPressed: onOpenPostInBrowserPressed)
        ]);
  }

  Widget buildAvatar() {
    if (avatarUrl != null) {
      return Padding(
          padding: EdgeInsets.fromLTRB(0.0, 0.0, 8.0, 0.0),
          child: CircleAvatar(
              foregroundImage: NetworkImage(avatarUrl!), radius: 20.0));
    }
    return Container();
  }
}

class PostCardButtons extends StatelessWidget {
  final Function()? onCopyPressed;
  final Function()? onSharePressed;
  final Function()? onOpenInBrowserPressed;

  const PostCardButtons(
      {super.key,
      this.onCopyPressed,
      this.onSharePressed,
      this.onOpenInBrowserPressed});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // Copy IconButton
      IconButton(
          iconSize: 24.0,
          onPressed: onCopyPressed,
          icon: const Icon(Icons.copy)),
      // Share IconButton
      IconButton(
          iconSize: 24.0,
          onPressed: onSharePressed,
          icon: const Icon(Icons.share)),
      IconButton(
          iconSize: 24.0,
          onPressed: onOpenInBrowserPressed,
          icon: const Icon(Icons.open_in_browser))
    ]);
  }
}

// class Avatar extends StatelessWidget {
//   final String? avatarUrl;
//   const Avatar({super.key, required this.avatarUrl});

//   @override
//   Widget build(BuildContext context) {
//     return avatarUrl != null
//         ? Align(
//             alignment: Alignment.topCenter,
//             child: Container(
//                 width: 40.0,
//                 height: 40.0,
//                 decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     image: DecorationImage(image: NetworkImage(avatarUrl!)))))
//         : Container();
//   }
// }
