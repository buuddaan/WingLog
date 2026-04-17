import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<BirdGroup> joinedGroups = [];
  List<BirdGroup> availableGroups = [
    BirdGroup(
      id: '1',
      name: 'Örnar & Rovfåglar',
      description: 'Diskutera och dela observationer av örnar, hök och falkar',
      memberCount: 1250,
      discussionCount: 342,
      newDiscussionCount: 3,
      isJoined: false,
      discussions: [
        Discussion(
          id: 'd1',
          title: 'Sällan se ödlehök på denna tid',
          author: 'BirdLover92',
          content: 'Observerade en sällsynt ödlehök igår vid sjön. Någon annan som sett dem här?',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          replies: 5,
          views: 23,
        ),
        Discussion(
          id: 'd2',
          title: 'Bästa platsen för falkkamera',
          author: 'FalconEye',
          content: 'Har köpt en ny buskamera. Var är bästa platsen att sätta upp den?',
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          replies: 8,
          views: 45,
        ),
      ],
    ),
    BirdGroup(
      id: '2',
      name: 'Vattenfåglar',
      description: 'Andfåglar, hägrar, skarvar och andra vattenlevande fåglar',
      memberCount: 856,
      discussionCount: 215,
      newDiscussionCount: 1,
      isJoined: false,
      discussions: [
        Discussion(
          id: 'd3',
          title: 'Häger migration har börjat',
          author: 'WaterBirdWatcher',
          content: 'De första när av häger har anlänt! Vilken är tidigaste du sett?',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          replies: 12,
          views: 67,
        ),
      ],
    ),
    BirdGroup(
      id: '3',
      name: 'Sångfåglar',
      description: 'Lövsångare, trastar, finkar och andra sångfåglar',
      memberCount: 2100,
      discussionCount: 567,
      newDiscussionCount: 5,
      isJoined: false,
      discussions: [
        Discussion(
          id: 'd4',
          title: 'Frost och sångfåglar',
          author: 'SongBirdFan',
          content: 'Hur påverkar frostnätterna sångfåglarnas migration?',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          replies: 15,
          views: 89,
        ),
      ],
    ),
    BirdGroup(
      id: '4',
      name: 'Sällsynta observationer',
      description: 'Dela och diskutera sällsynta och ovanliga fågelobservationer',
      memberCount: 634,
      discussionCount: 189,
      newDiscussionCount: 0,
      isJoined: false,
      discussions: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<BirdGroup> _filterGroups(List<BirdGroup> groups) {
    if (_searchQuery.isEmpty) {
      return groups;
    }
    return groups.where((group) =>
        group.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        group.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _joinGroup(BirdGroup group) {
    setState(() {
      group.isJoined = true;
      joinedGroups.add(group);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ansluten till ${group.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _leaveGroup(BirdGroup group) {
    setState(() {
      group.isJoined = false;
      joinedGroups.remove(group);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lämnade ${group.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredJoinedGroups = _filterGroups(joinedGroups);
    final filteredAvailableGroups = _filterGroups(availableGroups);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemenskap'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Sök grupper...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Mina grupper'),
              Tab(text: 'Upptäck'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // My Groups Tab
                filteredJoinedGroups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.groups_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Inga grupper anslutna ännu',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            const Text('Gå med i en grupp för att komma igång'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredJoinedGroups.length,
                        itemBuilder: (context, index) {
                          final group = filteredJoinedGroups[index];
                          return _buildGroupCard(group, isJoined: true);
                        },
                      ),
                // Discover Tab
                ListView.builder(
                  itemCount: filteredAvailableGroups.length,
                  itemBuilder: (context, index) {
                    final group = filteredAvailableGroups[index];
                    return _buildGroupCard(group, isJoined: group.isJoined);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BirdGroup group, {required bool isJoined}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: InkWell(
        onTap: isJoined ? () => _navigateToGroupDetails(group) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isJoined)
                  const Icon(Icons.check_circle, color: Colors.green),
                if (group.newDiscussionCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Badge(
                      label: Text(
                        group.newDiscussionCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  )
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${group.memberCount} medlemmar',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                Icon(Icons.chat, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${group.discussionCount} diskussioner',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isJoined
                    ? () => _leaveGroup(group)
                    : () => _joinGroup(group),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isJoined ? Colors.grey[300] : Colors.green,
                ),
                child: Text(
                  isJoined ? 'Lämna grupp' : 'Gå med i grupp',
                  style: TextStyle(
                    color: isJoined ? Colors.black87 : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _navigateToGroupDetails(BirdGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(group: group),
      ),
    );
  }
}

class BirdGroup {
  final String id;
  final String name;
  final String description;
  final int memberCount;
  final int discussionCount;
  int newDiscussionCount;
  bool isJoined;
  List<Discussion> discussions;

  BirdGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.discussionCount,
    this.newDiscussionCount = 0,
    this.isJoined = false,
    this.discussions = const [],
  });
}

class Discussion {
  final String id;
  final String title;
  final String author;
  final String content;
  final DateTime createdAt;
  final int replies;
  final int views;
  final bool isOriginalPoster;

  Discussion({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.replies,
    required this.views,
    this.isOriginalPoster = false,
  });
}

class GroupDetailsScreen extends StatefulWidget {
  final BirdGroup group;

  const GroupDetailsScreen({super.key, required this.group});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  late String _sortOrder = 'senaste';

  List<Discussion> _sortDiscussions(List<Discussion> discussions) {
    final sorted = List<Discussion>.from(discussions);
    switch (_sortOrder) {
      case 'senaste':
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'mest_aktiva':
        sorted.sort((a, b) => b.replies.compareTo(a.replies));
        break;
      case 'mina_fragor':
        sorted.sort((a, b) =>
            (b.isOriginalPoster ? 1 : 0).compareTo(a.isOriginalPoster ? 1 : 0));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sortedDiscussions = _sortDiscussions(widget.group.discussions);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewDiscussionDialog(),
        label: const Text('Ny tråd'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSortChip('Senaste', 'senaste'),
                  const SizedBox(width: 8),
                  _buildSortChip('Mest aktiva', 'mest_aktiva'),
                  const SizedBox(width: 8),
                  _buildSortChip('Mina frågor', 'mina_fragor'),
                ],
              ),
            ),
          ),
          Expanded(
            child: sortedDiscussions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Inga trådar ännu',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text('Starta en ny tråd för att komma igång'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedDiscussions.length,
                    itemBuilder: (context, index) {
                      final discussion = sortedDiscussions[index];
                      return _buildDiscussionCard(discussion);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _sortOrder == value,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _sortOrder = value;
          });
        }
      },
    );
  }

  Widget _buildDiscussionCard(Discussion discussion) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (discussion.isOriginalPoster)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'OP',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    discussion.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              discussion.author,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              discussion.content,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.reply, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${discussion.replies} svar',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${discussion.views} visningar',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Text(
                  _formatTime(discussion.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m sedan';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h sedan';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d sedan';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showNewDiscussionDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Starta en ny tråd'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Trådtitel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  hintText: 'Skriv ditt inlägg...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tråd skapad!'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
                titleController.dispose();
                contentController.dispose();
              }
            },
            child: const Text('Skapa tråd'),
          ),
        ],
      ),
    );
  }
}
