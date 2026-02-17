import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const TODOS_FILE = join(__dirname, '..', 'todos.json');

function loadTodos() {
  if (!existsSync(TODOS_FILE)) return [];
  return JSON.parse(readFileSync(TODOS_FILE, 'utf-8'));
}

function saveTodos(todos) {
  writeFileSync(TODOS_FILE, JSON.stringify(todos, null, 2));
}

const [,, command, ...args] = process.argv;

if (!command) {
  console.log('Usage: node src/index.js <command> [args]');
  console.log('Commands: add, list, done, delete');
  process.exit(0);
}

if (command === 'add') {
  const text = args.join(' ');
  if (!text) {
    console.log('Error: Please provide a todo text.');
    process.exit(1);
  }
  const todos = loadTodos();
  const id = todos.length > 0 ? Math.max(...todos.map(t => t.id)) + 1 : 1;
  todos.push({ id, text, done: false });
  saveTodos(todos);
  console.log(`Added todo #${id}: "${text}"`);
} else if (command === 'list') {
  const todos = loadTodos();
  if (todos.length === 0) {
    console.log('No todos yet. Add one with: node src/index.js add "Your task"');
  } else {
    for (const t of todos) {
      const status = t.done ? '[x]' : '[ ]';
      console.log(`${t.id}. ${status} ${t.text}`);
    }
  }
} else if (command === 'done') {
  const id = parseInt(args[0]);
  if (isNaN(id)) {
    console.log('Error: Please provide a valid todo id.');
    process.exit(1);
  }
  const todos = loadTodos();
  const todo = todos.find(t => t.id === id);
  if (!todo) {
    console.log(`Error: Todo #${id} not found.`);
    process.exit(1);
  }
  todo.done = true;
  saveTodos(todos);
  console.log(`Marked todo #${id} as done: "${todo.text}"`);
} else if (command === 'delete') {
  const id = parseInt(args[0]);
  if (isNaN(id)) {
    console.log('Error: Please provide a valid todo id.');
    process.exit(1);
  }
  const todos = loadTodos();
  const index = todos.findIndex(t => t.id === id);
  if (index === -1) {
    console.log(`Error: Todo #${id} not found.`);
    process.exit(1);
  }
  const removed = todos.splice(index, 1)[0];
  saveTodos(todos);
  console.log(`Deleted todo #${id}: "${removed.text}"`);
} else {
  console.log(`Unknown command: ${command}`);
  console.log('Commands: add, list, done, delete');
  process.exit(1);
}
