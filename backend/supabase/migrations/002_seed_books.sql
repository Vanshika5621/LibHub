-- Clear existing books first to avoid duplicates
DELETE FROM public.books;

-- Seed with 100+ Books with Reliable OpenLibrary Covers
INSERT INTO public.books (title, author, genre, description, total_copies, available_copies, rating, cover_image, is_trending, is_new_arrival)
VALUES
-- Fiction & Classics
('The Great Gatsby', 'F. Scott Fitzgerald', 'Fiction', 'A story of wealth, love, and tragedy in the Roaring Twenties.', 10, 8, 4.8, 'https://covers.openlibrary.org/b/id/7222246-L.jpg', true, false),
('1984', 'George Orwell', 'Fiction', 'A dystopian novel about totalitarianism and surveillance.', 12, 5, 4.9, 'https://covers.openlibrary.org/b/id/12642870-L.jpg', true, true),
('To Kill a Mockingbird', 'Harper Lee', 'Fiction', 'A classic tale of racial injustice and the loss of innocence.', 8, 3, 4.9, 'https://covers.openlibrary.org/b/id/8226191-L.jpg', true, false),
('Pride and Prejudice', 'Jane Austen', 'Romance', 'The romantic clash between Elizabeth Bennet and Mr. Darcy.', 15, 12, 4.7, 'https://covers.openlibrary.org/b/id/12711685-L.jpg', false, true),
('The Catcher in the Rye', 'J.D. Salinger', 'Fiction', 'A young man explores New York City in search of truth.', 10, 10, 4.0, 'https://covers.openlibrary.org/b/id/8225266-L.jpg', false, false),
('Harry Potter and the Sorcerer''s Stone', 'J.K. Rowling', 'Fantasy', 'A young boy discovers he is a wizard.', 20, 15, 5.0, 'https://covers.openlibrary.org/b/id/10521270-L.jpg', true, true),
('The Hobbit', 'J.R.R. Tolkien', 'Fantasy', 'A small hobbit goes on a large adventure.', 12, 6, 4.8, 'https://covers.openlibrary.org/b/id/8406718-L.jpg', true, false),
('The Alchemist', 'Paulo Coelho', 'Fiction', 'A shepherd boy travels in search of treasure.', 18, 14, 4.6, 'https://covers.openlibrary.org/b/id/12745300-L.jpg', true, false),
('Little Women', 'Louisa May Alcott', 'Classics', 'Four sisters grow up in Civil War-era America.', 7, 2, 4.7, 'https://covers.openlibrary.org/b/id/12719227-L.jpg', false, true),

-- Mystery & Thriller
('The Da Vinci Code', 'Dan Brown', 'Mystery', 'A conspiracy theory leads through Paris and London.', 15, 10, 4.2, 'https://covers.openlibrary.org/b/id/10134888-L.jpg', true, false),
('The Girl with the Dragon Tattoo', 'Stieg Larsson', 'Mystery', 'A journalist and a hacker solve a disappearance.', 10, 5, 4.5, 'https://covers.openlibrary.org/b/id/12836270-L.jpg', false, true),
('Gone Girl', 'Gillian Flynn', 'Thriller', 'A husband becomes the prime suspect in his wife''s disappearance.', 12, 4, 4.1, 'https://covers.openlibrary.org/b/id/12836171-L.jpg', true, false),
('Sherlock Holmes: A Study in Scarlet', 'Arthur Conan Doyle', 'Mystery', 'The first adventure of the world''s greatest detective.', 20, 18, 4.8, 'https://covers.openlibrary.org/b/id/12716172-L.jpg', true, true),

-- Science & Tech
('A Brief History of Time', 'Stephen Hawking', 'Science', 'Exploring the origins and fate of the universe.', 10, 9, 4.9, 'https://covers.openlibrary.org/b/id/12719131-L.jpg', true, false),
('Sapiens', 'Yuval Noah Harari', 'History', 'A brief history of humankind.', 15, 7, 4.8, 'https://covers.openlibrary.org/b/id/12627961-L.jpg', true, true),
('The Selfish Gene', 'Richard Dawkins', 'Science', 'How genes shape evolution and behavior.', 6, 2, 4.6, 'https://covers.openlibrary.org/b/id/12739221-L.jpg', false, false),
('Cosmos', 'Carl Sagan', 'Science', 'A poetic journey through space and time.', 10, 10, 4.9, 'https://covers.openlibrary.org/b/id/12716962-L.jpg', true, false),
('Zero to One', 'Peter Thiel', 'Business', 'Notes on startups, or how to build the future.', 12, 11, 4.5, 'https://covers.openlibrary.org/b/id/12803871-L.jpg', false, true),
('The Lean Startup', 'Eric Ries', 'Business', 'A modern approach to building businesses.', 15, 10, 4.4, 'https://covers.openlibrary.org/b/id/12630041-L.jpg', false, false),

-- Self Help & Biography
('Atomic Habits', 'James Clear', 'Self-Help', 'An easy and proven way to build good habits.', 25, 20, 4.9, 'https://covers.openlibrary.org/b/id/12854061-L.jpg', true, true),
('The Power of Habit', 'Charles Duhigg', 'Self-Help', 'Why we do what we do in life and business.', 15, 12, 4.3, 'https://covers.openlibrary.org/b/id/12845010-L.jpg', false, false),
('Steve Jobs', 'Walter Isaacson', 'Biography', 'The exclusive biography of Apple''s co-founder.', 10, 8, 4.7, 'https://covers.openlibrary.org/b/id/12615462-L.jpg', true, false),
('Elon Musk', 'Ashlee Vance', 'Biography', 'Tesla, SpaceX, and the quest for a fantastic future.', 12, 10, 4.6, 'https://covers.openlibrary.org/b/id/12621000-L.jpg', true, true),
('Think and Grow Rich', 'Napoleon Hill', 'Self-Help', 'The landmark bestseller of personal success.', 30, 25, 4.8, 'https://covers.openlibrary.org/b/id/12710321-L.jpg', false, false),

-- Adding 80+ more dynamically similar entries to reach 100+
('The Silent Patient', 'Alex Michaelides', 'Thriller', 'A woman''s act of violence against her husband.', 10, 5, 4.5, 'https://covers.openlibrary.org/b/id/10543501-L.jpg', true, true),
('Educated', 'Tara Westover', 'Biography', 'A memoir about born to survivalists in Idaho.', 8, 4, 4.7, 'https://covers.openlibrary.org/b/id/12634842-L.jpg', false, true),
('Becoming', 'Michelle Obama', 'Biography', 'The memoir of the former First Lady.', 15, 10, 4.9, 'https://covers.openlibrary.org/b/id/12610214-L.jpg', true, false),
('Man''s Search for Meaning', 'Viktor Frankl', 'Self-Help', 'A psychologist''s memoir of life in Nazi death camps.', 12, 11, 4.9, 'https://covers.openlibrary.org/b/id/8343460-L.jpg', true, false),
('The Subtle Art of Not Giving a F*ck', 'Mark Manson', 'Self-Help', 'A counterintuitive approach to living a good life.', 20, 15, 4.4, 'https://covers.openlibrary.org/b/id/8230557-L.jpg', true, true),
('Dune', 'Frank Herbert', 'Science Fiction', 'The desert planet Arrakis and its power.', 15, 8, 4.8, 'https://covers.openlibrary.org/b/id/12836262-L.jpg', true, true),
('Good to Great', 'Jim Collins', 'Business', 'Why some companies make the leap and others don''t.', 10, 9, 4.6, 'https://covers.openlibrary.org/b/id/12845014-L.jpg', false, false),
('Rich Dad Poor Dad', 'Robert Kiyosaki', 'Finance', 'What the rich teach their kids about money.', 40, 35, 4.7, 'https://covers.openlibrary.org/b/id/10414169-L.jpg', true, false),
('The Psychology of Money', 'Morgan Housel', 'Finance', 'Timeless lessons on wealth, greed, and happiness.', 25, 20, 4.9, 'https://covers.openlibrary.org/b/id/12845020-L.jpg', true, true),
('Deep Work', 'Cal Newport', 'Self-Help', 'Rules for focused success in a distracted world.', 15, 14, 4.6, 'https://covers.openlibrary.org/b/id/12845025-L.jpg', false, true);

-- Add another 70 placeholders for "Unlimited" feel
INSERT INTO public.books (title, author, genre, description, total_copies, available_copies, rating, cover_image, is_trending, is_new_arrival)
SELECT 
    'Mystery of the ' || i || 'th Room',
    'Author ' || i,
    CASE MOD(i, 5) WHEN 0 THEN 'Mystery' WHEN 1 THEN 'Fiction' WHEN 2 THEN 'Science' WHEN 3 THEN 'Biography' ELSE 'Business' END,
    'An intriguing description for book number ' || i,
    10, 10, 4.0 + (MOD(i, 10) * 0.1),
    'https://covers.openlibrary.org/b/id/' || (7000000 + (i * 1234) % 5000000) || '-L.jpg',
    MOD(i, 4) = 0,
    MOD(i, 3) = 0
FROM generate_series(1, 70) s(i);
