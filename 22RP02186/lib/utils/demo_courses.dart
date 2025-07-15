import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> insertDemoCourses() async {
  final demoCourses = [
    {
      'title': 'Digital Marketing Basics',
      'category': 'Digital Skills',
      'description': 'Learn the fundamentals of digital marketing, including SEO, social media, and email campaigns. This course is perfect for beginners and small business owners who want to grow their online presence.',
      'image': 'assets/digital-skills.png',
      'trainerEmail': 'demo_trainer@skillslinks.com',
      'trainerName': 'Demo Trainer',
      'isPremium': false,
      'studentsEnrolled': 25,
      'createdAt': FieldValue.serverTimestamp(),
      'jobReady': true,
      'lessons': [
        {
          'title': 'Introduction to Digital Marketing',
          'content': 'Discover what digital marketing is, why it matters, and how it can help you reach more customers. We cover the basics and set the stage for the rest of the course.',
          'videoURL': 'https://www.youtube.com/watch?v=nJmGrNdJ5Gw',
          'isPremium': false,
          'duration': '10 min',
          'subtopics': [
            'Definition of digital marketing',
            'Key benefits',
            'Overview of digital channels',
          ],
        },
        {
          'title': 'SEO Basics',
          'content': 'Learn how to optimize your website for search engines. Topics include keyword research, on-page SEO, and link building strategies.',
          'videoURL': 'https://www.youtube.com/watch?v=E1SxQd5yUjA',
          'isPremium': true,
          'duration': '15 min',
          'subtopics': [
            'What is SEO?',
            'Keyword research',
            'On-page optimization',
            'Link building',
          ],
        },
        {
          'title': 'Social Media Marketing',
          'content': 'Explore how to use platforms like Facebook, Instagram, and Twitter to grow your brand. Learn about content planning, engagement, and analytics.',
          'videoURL': 'https://www.youtube.com/watch?v=V0vQkSuR8h4',
          'isPremium': false,
          'duration': '12 min',
          'subtopics': [
            'Choosing the right platform',
            'Content planning',
            'Measuring success',
          ],
        },
        {
          'title': 'Email Campaigns',
          'content': 'Master the basics of email marketing, including building a list, crafting effective emails, and measuring results.',
          'videoURL': 'https://www.youtube.com/watch?v=QAy6gkGQw88',
          'isPremium': false,
          'duration': '10 min',
          'subtopics': [
            'Building an email list',
            'Writing engaging emails',
            'Tracking open rates',
          ],
        },
      ],
    },
    {
      'title': 'Baking for Beginners',
      'category': 'Cooking',
      'description': 'Start your baking journey with easy recipes and tips from a pro. This course covers everything from tools to your first cake.',
      'image': 'assets/cooking.png',
      'trainerEmail': 'demo_trainer@skillslinks.com',
      'trainerName': 'Demo Trainer',
      'isPremium': true,
      'price': 19.99,
      'studentsEnrolled': 12,
      'createdAt': FieldValue.serverTimestamp(),
      'jobReady': false,
      'lessons': [
        {
          'title': 'Baking Tools',
          'content': 'Essential tools for every baker. Learn about measuring cups, mixing bowls, spatulas, and more. We also discuss how to care for your tools.',
          'videoURL': 'https://www.youtube.com/watch?v=1APwq1df6Mw',
          'isPremium': false,
          'duration': '8 min',
          'subtopics': [
            'Measuring tools',
            'Mixing equipment',
            'Oven basics',
          ],
        },
        {
          'title': 'Ingredients 101',
          'content': 'Understand the role of flour, sugar, eggs, and other key ingredients in baking. Learn how to choose the best ingredients for your recipes.',
          'videoURL': 'https://www.youtube.com/watch?v=Q1U3FQ2pK5A',
          'isPremium': false,
          'duration': '10 min',
          'subtopics': [
            'Types of flour',
            'Sweeteners',
            'Leavening agents',
          ],
        },
        {
          'title': 'First Cake',
          'content': 'Step-by-step guide to baking your first cake. We cover mixing, baking, and decorating basics.',
          'videoURL': 'https://www.youtube.com/watch?v=QFQyib5ZQZY',
          'isPremium': true,
          'duration': '15 min',
          'subtopics': [
            'Mixing batter',
            'Baking tips',
            'Simple decoration',
          ],
        },
      ],
    },
    {
      'title': 'Guitar for Everyone',
      'category': 'Music',
      'description': 'Learn to play guitar from scratch. Chords, strumming, and your first song! This course is designed for absolute beginners.',
      'image': 'assets/music.jpg',
      'trainerEmail': 'demo_trainer@skillslinks.com',
      'trainerName': 'Demo Trainer',
      'isPremium': false,
      'studentsEnrolled': 30,
      'createdAt': FieldValue.serverTimestamp(),
      'jobReady': false,
      'lessons': [
        {
          'title': 'Guitar Basics',
          'content': 'Parts of the guitar and tuning. Learn how to hold the guitar, tune it, and basic maintenance.',
          'videoURL': 'https://www.youtube.com/watch?v=2wP1yiJ4O2A',
          'isPremium': false,
          'duration': '10 min',
          'subtopics': [
            'Guitar anatomy',
            'Tuning methods',
            'Basic care',
          ],
        },
        {
          'title': 'First Chords',
          'content': 'Learn your first chords and how to switch between them. Practice with simple chord progressions.',
          'videoURL': 'https://www.youtube.com/watch?v=5mgwOJ9xg6A',
          'isPremium': false,
          'duration': '12 min',
          'subtopics': [
            'Major chords',
            'Minor chords',
            'Chord transitions',
          ],
        },
        {
          'title': 'Strumming Patterns',
          'content': 'Master basic strumming patterns to play along with your favorite songs.',
          'videoURL': 'https://www.youtube.com/watch?v=6Jb1uGkQz4E',
          'isPremium': false,
          'duration': '10 min',
          'subtopics': [
            'Downstrokes',
            'Upstrokes',
            'Rhythm practice',
          ],
        },
        {
          'title': 'Your First Song',
          'content': 'Put it all together and play your first song on the guitar. We use a simple, popular tune for beginners.',
          'videoURL': 'https://www.youtube.com/watch?v=2Vv-BfVoq4g',
          'isPremium': true,
          'duration': '15 min',
          'subtopics': [
            'Song structure',
            'Playing with chords',
            'Performance tips',
          ],
        },
      ],
    },
    {
      'title': 'Fitness at Home',
      'category': 'Health & Fitness',
      'description': 'No gym? No problem! Get fit with home workouts and nutrition tips. This course is for all levels.',
      'image': 'assets/Health&Fitness.jpg',
      'trainerEmail': 'demo_trainer@skillslinks.com',
      'trainerName': 'Demo Trainer',
      'isPremium': false,
      'studentsEnrolled': 18,
      'createdAt': FieldValue.serverTimestamp(),
      'jobReady': true,
      'lessons': [
        {
          'title': 'Warm Up',
          'content': '''A proper warm-up is essential before any workout. It prepares your body for exercise, increases blood flow to your muscles, and reduces the risk of injury. 

**Theory:**
- Warming up gradually increases your heart rate and circulation, loosens the joints, and increases blood flow to the muscles.
- It helps mentally prepare you for the workout ahead.

**Practical Steps:**
1. Start with 3-5 minutes of light cardio (marching in place, brisk walking, or gentle jogging).
2. Perform dynamic stretches such as arm circles, leg swings, and torso twists.
3. Focus on full-body movements to activate all major muscle groups.

**Example Routine:**
- 30 seconds jumping jacks
- 30 seconds arm circles
- 30 seconds high knees
- 30 seconds bodyweight squats
- 30 seconds lunges (alternating legs)

**Video Guide:**
Watch the video for a guided warm-up routine you can follow along with.''',
          'videoURL': 'https://www.youtube.com/watch?v=6vQpW9XRiyM',
          'isPremium': false,
          'duration': '8 min',
          'subtopics': [
            'Dynamic stretching',
            'Joint mobility',
            'Injury prevention',
          ],
        },
        {
          'title': 'Full Body Workout',
          'content': '''This lesson covers a simple, effective full-body workout you can do at home with no equipment.

**Theory:**
- Full-body workouts target all major muscle groups in a single session.
- They help improve strength, endurance, and overall fitness.

**Practical Steps:**
1. Perform each exercise for 30-45 seconds, rest for 15 seconds between exercises.
2. Complete 2-3 rounds for a full workout.

**Sample Exercises:**
- Push-ups
- Bodyweight squats
- Plank
- Mountain climbers
- Glute bridges

**Tips:**
- Focus on proper form over speed.
- Modify exercises as needed for your fitness level.

**Video Guide:**
Follow along with the video for a guided session.''',
          'videoURL': 'https://www.youtube.com/watch?v=UBMk30rjy0o',
          'isPremium': false,
          'duration': '15 min',
          'subtopics': [
            'Bodyweight exercises',
            'Reps and sets',
            'Cool down',
          ],
        },
        {
          'title': 'Nutrition Basics',
          'content': '''Good nutrition is key to supporting your fitness goals. This lesson covers the basics of healthy eating.

**Theory:**
- Macronutrients: Carbohydrates, proteins, and fats are all important for energy and recovery.
- Hydration: Drink plenty of water before, during, and after exercise.

**Practical Tips:**
- Plan balanced meals with a mix of protein, carbs, and healthy fats.
- Include plenty of fruits and vegetables.
- Avoid processed foods and sugary drinks.

**Sample Meal Plan:**
- Breakfast: Oatmeal with fruit and nuts
- Lunch: Grilled chicken salad with olive oil dressing
- Snack: Greek yogurt with berries
- Dinner: Baked salmon, brown rice, and steamed broccoli

**Video Guide:**
Watch the video for more nutrition tips and meal ideas.''',
          'videoURL': 'https://www.youtube.com/watch?v=Q4q3t0a8Y2E',
          'isPremium': false,
          'duration': '10 min',
          'subtopics': [
            'Macronutrients',
            'Meal planning',
            'Hydration',
          ],
        },
      ],
    },
    {
      'title': 'Mastering Public Speaking',
      'category': 'Communication',
      'description': 'A comprehensive course to help you become a confident and effective public speaker. Learn techniques, overcome stage fright, and deliver memorable presentations.',
      'image': 'assets/Communication-skills.png',
      'trainerEmail': 'pro_trainer@skillslinks.com',
      'trainerName': 'Pro Trainer',
      'isPremium': true,
      'price': 24.99,
      'studentsEnrolled': 8,
      'createdAt': FieldValue.serverTimestamp(),
      'jobReady': true,
      'lessons': [
        {
          'title': 'Introduction to Public Speaking',
          'content': 'Understand the basics of public speaking, its importance, and what you will learn in this course.',
          'videoURL': 'https://www.youtube.com/watch?v=ZXsQAXx_ao0',
          'isPremium': false,
          'duration': '15 min',
          'subtopics': [
            'What is public speaking?',
            'Why is it important?',
            'Course overview',
          ],
        },
        {
          'title': 'Overcoming Stage Fright',
          'content': 'Learn practical techniques to manage and overcome the fear of speaking in front of an audience.',
          'videoURL': 'https://www.youtube.com/watch?v=2Oe6HUgrRlQ',
          'isPremium': false,
          'duration': '20 min',
          'subtopics': [
            'Understanding stage fright',
            'Breathing exercises',
            'Visualization techniques',
          ],
        },
        {
          'title': 'Crafting Your Speech',
          'content': 'Step-by-step guide to writing a compelling and structured speech that keeps your audience engaged.',
          'videoURL': 'https://www.youtube.com/watch?v=5T68TvdoSbI',
          'isPremium': false,
          'duration': '25 min',
          'subtopics': [
            'Speech structure',
            'Opening and closing',
            'Storytelling',
          ],
        },
        {
          'title': 'Delivering with Confidence',
          'content': 'Master body language, voice modulation, and audience interaction to deliver your speech with confidence.',
          'videoURL': 'https://www.youtube.com/watch?v=03EDbFq5aNA',
          'isPremium': true,
          'duration': '30 min',
          'subtopics': [
            'Body language tips',
            'Voice control',
            'Handling questions',
          ],
        },
        {
          'title': 'Advanced Presentation Skills',
          'content': 'Take your presentations to the next level with advanced techniques and real-world practice.',
          'videoURL': 'https://www.youtube.com/watch?v=NU7W7qe2R0A',
          'isPremium': true,
          'duration': '35 min',
          'subtopics': [
            'Using visual aids',
            'Engaging your audience',
            'Dealing with difficult situations',
          ],
        },
      ],
    },
  ];

  // Remove duplicate courses by normalized title and description
  String normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  final uniqueCourses = <String, Map<String, dynamic>>{};
  for (final course in demoCourses) {
    final title = normalize((course['title'] ?? '').toString());
    final desc = normalize((course['description'] ?? '').toString());
    final key = '$title|$desc';
    if (!uniqueCourses.containsKey(key)) {
      // Remove duplicate lessons by title within this course
      final lessons = (course['lessons'] as List<dynamic>? ?? []).toList();
      final uniqueLessons = <String, Map<String, dynamic>>{};
      for (final lesson in lessons) {
        final lessonTitle = normalize((lesson['title'] ?? '').toString());
        if (!uniqueLessons.containsKey(lessonTitle)) {
          uniqueLessons[lessonTitle] = lesson;
        }
      }
      course['lessons'] = uniqueLessons.values.toList();
      uniqueCourses[key] = course;
    }
  }
  final coursesRef = FirebaseFirestore.instance.collection('courses');
  for (final course in uniqueCourses.values) {
    await coursesRef.add(course);
  }
}

Future<void> autoGenerateJobsForJobReadyCourses() async {
  final coursesRef = FirebaseFirestore.instance.collection('courses');
  final jobsRef = FirebaseFirestore.instance.collection('jobs');
  final coursesSnap = await coursesRef.get();
  for (final doc in coursesSnap.docs) {
    final course = doc.data();
    final courseId = doc.id;
    if (course['jobReady'] == true) {
      // Check if a job already exists for this course
      final existingJobSnap = await jobsRef.where('courseId', isEqualTo: courseId).limit(1).get();
      if (existingJobSnap.docs.isEmpty) {
        // Compose job info from course
        final jobData = {
          'courseId': courseId,
          'title': course['title'] ?? 'Job Opportunity',
          'description': course['description'] ?? '',
          'requiredSkills': [course['title'] ?? ''],
          'company': course['trainerName'] ?? 'SkillsLinks Trainer',
          'location': 'Remote',
          'createdAt': FieldValue.serverTimestamp(),
        };
        await jobsRef.add(jobData);
      }
    }
  }
} 