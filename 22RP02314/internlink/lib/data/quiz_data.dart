class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({required this.question, required this.options, required this.correctIndex});
}

final List<QuizQuestion> skillQuizQuestionsPool = [
  QuizQuestion(
    question: 'What does HTML stand for?',
    options: [
      'Hyper Trainer Marking Language',
      'Hyper Text Markup Language',
      'Hyper Text Marketing Language',
      'Hyper Text Markup Leveler',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Which language is used for styling web pages?',
    options: [
      'HTML',
      'JQuery',
      'CSS',
      'XML',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Which is not a JavaScript Framework?',
    options: [
      'Python Script',
      'JQuery',
      'Django',
      'NodeJS',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Which is used for Connect To Database?',
    options: [
      'PHP',
      'HTML',
      'JS',
      'All',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    question: 'Which of the following is a version control system?',
    options: [
      'Git',
      'Node.js',
      'React',
      'Dart',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    question: 'What does CSS stand for?',
    options: [
      'Cascading Style Sheets',
      'Colorful Style Sheets',
      'Computer Style Sheets',
      'Creative Style Sheets',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    question: 'Which HTML tag is used to define an internal style sheet?',
    options: [
      '<css>',
      '<script>',
      '<style>',
      '<link>',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Which property is used to change the background color in CSS?',
    options: [
      'color',
      'background-color',
      'bgcolor',
      'background',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Inside which HTML element do we put the JavaScript?',
    options: [
      '<js>',
      '<scripting>',
      '<script>',
      '<javascript>',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Which company developed JavaScript?',
    options: [
      'Mozilla',
      'Netscape',
      'Google',
      'Microsoft',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Which of the following is not a programming language?',
    options: [
      'Python',
      'HTML',
      'Java',
      'C++',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Which method is used to print something in the console in JavaScript?',
    options: [
      'console.print()',
      'print()',
      'console.log()',
      'log()',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Which HTML attribute is used to define inline styles?',
    options: [
      'font',
      'styles',
      'style',
      'class',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'Which symbol is used for comments in CSS?',
    options: [
      '//',
      '/* */',
      '<!-- -->',
      '#',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Which of the following is a backend language?',
    options: [
      'HTML',
      'CSS',
      'Java',
      'React',
    ],
    correctIndex: 2,
  ),
  QuizQuestion(
    question: 'What does SQL stand for?',
    options: [
      'Structured Query Language',
      'Strong Question Language',
      'Structured Question Language',
      'Simple Query Language',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    question: 'Which tag is used to create a hyperlink in HTML?',
    options: [
      '<a>',
      '<link>',
      '<href>',
      '<hyperlink>',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    question: 'Which of the following is a frontend framework?',
    options: [
      'Django',
      'React',
      'Laravel',
      'Flask',
    ],
    correctIndex: 1,
  ),
  QuizQuestion(
    question: 'Which is not a database?',
    options: [
      'MongoDB',
      'MySQL',
      'Oracle',
      'React',
    ],
    correctIndex: 3,
  ),
  QuizQuestion(
    question: 'Which language runs in a web browser?',
    options: [
      'Java',
      'C',
      'Python',
      'JavaScript',
    ],
    correctIndex: 3,
  ),
  QuizQuestion(
    question: 'Which of the following is used to style React components?',
    options: [
      'CSS',
      'JSX',
      'HTML',
      'SQL',
    ],
    correctIndex: 0,
  ),
  QuizQuestion(
    question: 'Which of the following is a NoSQL database?',
    options: [
      'MySQL',
      'MongoDB',
      'PostgreSQL',
      'Oracle',
    ],
    correctIndex: 1,
  ),
]; 