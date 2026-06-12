-- 1. DELETE ALL EXISTING BOOKS
DELETE FROM public.books;

-- 2. INSERT 120+ BOOKS WITH ALL CATEGORIES
INSERT INTO public.books (title, author, genre, description, total_copies, available_copies, rating, cover_image, is_trending, is_new_arrival)
VALUES
-- NON-FICTION
('The Immortal Life of Henrietta Lacks', 'Rebecca Skloot', 'Non-Fiction', 'The story of cells taken without consent.', 10, 5, 4.7, 'https://covers.openlibrary.org/b/id/12627441-L.jpg', true, false),
('Into the Wild', 'Jon Krakauer', 'Non-Fiction', 'A young man''s journey into the Alaskan wilderness.', 8, 3, 4.5, 'https://covers.openlibrary.org/b/id/12836214-L.jpg', false, true),
('The Tipping Point', 'Malcolm Gladwell', 'Non-Fiction', 'How little things can make a big difference.', 12, 10, 4.3, 'https://covers.openlibrary.org/b/id/10531557-L.jpg', true, false),
('Quiet', 'Susan Cain', 'Non-Fiction', 'The power of introverts in a world that can''t stop talking.', 15, 12, 4.8, 'https://covers.openlibrary.org/b/id/12845030-L.jpg', false, true),
('Thinking, Fast and Slow', 'Daniel Kahneman', 'Non-Fiction', 'Exploration of the two systems that drive the way we think.', 10, 8, 4.9, 'https://covers.openlibrary.org/b/id/12627964-L.jpg', true, false),

-- TECHNOLOGY
('Clean Code', 'Robert C. Martin', 'Technology', 'A handbook of agile software craftsmanship.', 20, 15, 4.9, 'https://covers.openlibrary.org/b/id/12621020-L.jpg', true, true),
('The Pragmatic Programmer', 'Andrew Hunt', 'Technology', 'Standard for intermediate to advanced programmers.', 15, 8, 4.9, 'https://covers.openlibrary.org/b/id/12621025-L.jpg', true, false),
('Design Patterns', 'Erich Gamma', 'Technology', 'Elements of reusable object-oriented software.', 10, 4, 4.8, 'https://covers.openlibrary.org/b/id/12621030-L.jpg', false, true),
('Introduction to Algorithms', 'Thomas H. Cormen', 'Technology', 'The most popular textbook on algorithms.', 5, 2, 4.9, 'https://covers.openlibrary.org/b/id/12615467-L.jpg', true, false),
('Code Complete', 'Steve McConnell', 'Technology', 'A practical handbook of software construction.', 12, 0, 4.7, 'https://covers.openlibrary.org/b/id/12621035-L.jpg', false, false),

-- HISTORY
('Guns, Germs, and Steel', 'Jared Diamond', 'History', 'The fates of human societies.', 10, 5, 4.6, 'https://covers.openlibrary.org/b/id/12627961-L.jpg', true, false),
('The Rise and Fall of the Third Reich', 'William L. Shirer', 'History', 'History of Nazi Germany.', 8, 2, 4.8, 'https://covers.openlibrary.org/b/id/12627970-L.jpg', false, true),
('SPQR: A History of Ancient Rome', 'Mary Beard', 'History', 'Exploring the Roman Empire.', 12, 10, 4.7, 'https://covers.openlibrary.org/b/id/12621040-L.jpg', true, false),

-- FICTION & OTHERS
('The Great Gatsby', 'F. Scott Fitzgerald', 'Fiction', 'A story of wealth, love, and tragedy.', 10, 8, 4.8, 'https://covers.openlibrary.org/b/id/7222246-L.jpg', true, false),
('1984', 'George Orwell', 'Fiction', 'A dystopian novel about totalitarianism.', 12, 0, 4.9, 'https://covers.openlibrary.org/b/id/12642870-L.jpg', true, true),
('The Hobbit', 'J.R.R. Tolkien', 'Fantasy', 'A small hobbit goes on a large adventure.', 12, 6, 4.8, 'https://covers.openlibrary.org/b/id/8406718-L.jpg', true, false);

-- 3. ADD 100 MORE DYNAMICALLY
INSERT INTO public.books (title, author, genre, description, total_copies, available_copies, rating, cover_image, is_trending, is_new_arrival)
SELECT 
    'Knowledge of ' || i || 'th Century',
    'Scholar ' || i,
    CASE   
        WHEN MOD(i, 6) = 0 THEN 'Science' 
        WHEN MOD(i, 6) = 1 THEN 'Fiction' 
        WHEN MOD(i, 6) = 2 THEN 'Technology' 
        WHEN MOD(i, 6) = 3 THEN 'History' 
        WHEN MOD(i, 6) = 4 THEN 'Non-Fiction' 
        ELSE 'Biography' 
    END,
    'Exploring deep insights of ' || i || ' and more.',
    (10 + i % 10), 
    CASE WHEN MOD(i, 4) = 0 THEN 0 ELSE 5 END, -- Every 4th book is Reserve-only (0 copies)
    (4.0 + (i % 10) * 0.1),
    'https://covers.openlibrary.org/b/id/' || (7000000 + (i * 4321) % 5000000) || '-L.jpg',
    (i % 5 = 0), (i % 7 = 0)
FROM generate_series(1, 100) s(i);
