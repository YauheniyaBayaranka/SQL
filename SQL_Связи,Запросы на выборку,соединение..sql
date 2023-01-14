-----СВЯЗИ МЕЖДУ ТАБЛИЦАМИ

/*** 1. Создать таблицу author следующей структуры:
Поле	Тип, описание
author_id	     INT PRIMARY KEY AUTO_INCREMENT
name_author	VARCHAR(50) */

create table author(
author_id	INT PRIMARY KEY AUTO_INCREMENT,
name_author VARCHAR(50));

/***2. Заполнить таблицу author. В нее включить следующих авторов:
Булгаков М.А.
Достоевский Ф.М.
Есенин С.А.
Пастернак Б.Л.*/

INSERT INTO author (name_author)
VALUES
    ('Булгаков М.А.'),
    ('Достоевский Ф.М.'),
    ('Есенин С.А.'),
    ('Пастернак Б.Л.');

/**** 3. Перепишите запрос на создание таблицы book , чтобы ее структура соответствовала структуре, показанной на логической схеме (таблица genre уже создана, порядок следования столбцов - как на логической схеме в таблице book, genre_id  - внешний ключ) . Для genre_id ограничение о недопустимости пустых значений не задавать. В качестве главной таблицы для описания поля  genre_idиспользовать таблицу genre следующей структуры:
Поле	Тип, описание
genre_id	INT PRIMARY KEY AUTO_INCREMENT
name_genre	VARCHAR(30)*/

CREATE TABLE book (
    book_id INT PRIMARY KEY AUTO_INCREMENT, 
    title VARCHAR(50), 
    author_id INT NOT NULL, 
    genre_id INT,
    price DECIMAL(8,2), 
    amount INT, 
    FOREIGN KEY (author_id)  REFERENCES author (author_id),
    FOREIGN KEY (genre_id)  REFERENCES genre (genre_id)
);

/***4. Создать таблицу book той же структуры, что и на предыдущем шаге. Будем считать, что при удалении автора из таблицы author, должны удаляться все записи о книгах из таблицы book, написанные этим автором. А при удалении жанра из таблицы genre для соответствующей записи book установить значение Null в столбце genre_id. */

CREATE TABLE book (
    book_id INT PRIMARY KEY AUTO_INCREMENT, 
    title VARCHAR(50), 
    author_id INT NOT NULL, 
    genre_id INT,
    price DECIMAL(8,2), 
    amount INT, 
    FOREIGN KEY (author_id)  REFERENCES author (author_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id)  REFERENCES genre (genre_id) ON DELETE SET NULL
);

--ЗАПРОСЫ НА ВЫБОРКУ, СОЕДИНЕНИЕ ТАБЛИЦ

/* 1. Вывести название, жанр и цену тех книг, количество которых больше 8, в отсортированном по убыванию цены виде.*/

SELECT title, name_genre, price
FROM genre as g INNER JOIN book as b
ON g.genre_id = b.genre_id
where b.amount > 8
order by price desc;

/* 2. Вывести все жанры, которые не представлены в книгах на складе.*/

select name_genre 
from genre as g left join book as b
on g.genre_id = b.genre_id
where title is null;

/* 3. Необходимо в каждом городе провести выставку книг каждого автора в течение 2020 года. Дату проведения выставки выбрать случайным образом. Создать запрос, который выведет город, автора и дату проведения выставки. Последний столбец назвать Дата. Информацию вывести, отсортировав сначала в алфавитном порядке по названиям городов, а потом по убыванию дат проведения выставок.*/

select name_city, name_author, DATE_ADD('2020-01-01',INTERVAL FLOOR(RAND() * 365) DAY) AS  Дата
from city, author
order by name_city,  Дата desc;

/* 4.  Вывести информацию о книгах (жанр, книга, автор), относящихся к жанру, включающему слово «роман» в отсортированном по названиям книг виде*/

SELECT name_genre, title, name_author
FROM author 
    INNER JOIN  book ON author.author_id = book.author_id
    INNER JOIN genre ON genre.genre_id = book.genre_id and name_genre = 'Роман'
WHERE name_genre = 'Роман'
ORDER BY title;

/* 5. Посчитать количество экземпляров  книг каждого автора из таблицы author.  Вывести тех авторов,  количество книг которых меньше 10, в отсортированном по возрастанию количества виде. Последний столбец назвать Количество*/

select name_author, sum(amount) as Количество
from 
    author as a left join book as b
    on a.author_id = b.author_id
group by name_author
having sum(amount)<10 or sum(amount) is null
order by sum(amount);

/* 6. Вывести в алфавитном порядке всех авторов, которые пишут только в одном жанре. Поскольку у нас в таблицах так занесены данные, что у каждого автора книги только в одном жанре,  для этого запроса внесем изменения в таблицу book. Пусть у нас  книга Есенина «Черный человек» относится к жанру «Роман», а книга Булгакова «Белая гвардия» к «Приключениям» (эти изменения в таблицы уже внесены).*/

SELECT name_author 
FROM author
  LEFT JOIN book
  ON author.author_id = book.author_id
GROUP BY author.author_id
HAVING MIN(genre_id) = MAX(genre_id)
ORDER BY name_author;

/* 7. Вывести информацию о книгах (название книги, фамилию и инициалы автора, название жанра, цену и количество экземпляров книги), написанных в самых популярных жанрах, в отсортированном в алфавитном порядке по названию книг виде. Самым популярным считать жанр, общее количество экземпляров книг которого на складе максимально.*/

select title, name_author, name_genre, price*1.5, amount
from author 
        inner join book on author.author_id = book.author_id
        inner join genre on genre.genre_id = book.genre_id
where book.title not like '_% _%' and book.genre_id in( 
                  SELECT genre_id
                  FROM book
                  GROUP BY genre_id
                  HAVING avg(amount) <= ALL(SELECT SUM(amount) as ss
                                            from book 
                                            group by genre_id))
order by title, name_author, amount desc;

-- ЗАПРОСЫ КОРРЕКТИРОВКИ, СОЕДИНЕНИЕ ТАБЛИЦ

/* 1. Для книг, которые уже есть на складе (в таблице book), но по другой цене, чем в поставке (supply),  необходимо в таблице book увеличить количество на значение, указанное в поставке,  и пересчитать цену. А в таблице  supply обнулить количество этих книг.*/

update author 
INNER JOIN book  ON author.author_id = book.author_id
INNER JOIN supply ON book.title = supply.title 
                          and supply.author = author.name_author
                          and supply.price <> book.price
set book.amount = book.amount+supply.amount,
book.price= (book.price*book.amount+supply.price*supply.amount)/(book.amount+supply.amount),
supply.amount=0;

/* 2. Включить новых авторов в таблицу author с помощью запроса на добавление, а затем вывести все данные из таблицы author.  Новыми считаются авторы, которые есть в таблице supply, но нет в таблице author.*/

insert author(name_author)
select supply.author
from supply left join author on supply.author = author.name_author
where author.name_author is null;

/* 3. Добавить новые книги из таблицы supply в таблицу book на основе сформированного выше запроса. Затем вывести для просмотра таблицу book.*/

insert book(title, author_id, price, amount)
SELECT title, author_id, price, amount
FROM 
    author 
    INNER JOIN supply ON author.name_author = supply.author
WHERE amount <> 0;

/* 4. Занести для книги «Стихотворения и поэмы» Лермонтова жанр «Поэзия», а для книги «Остров сокровищ» Стивенсона - «Приключения». (Использовать два запроса).*/

update book
set genre_id = (select genre_id
                from genre
                where name_genre = 'Поэзия')
where book_id = 10;

update book
set genre_id = (select genre_id
from genre
where name_genre = 'Приключения')
where book_id = 11;

/* 5. Удалить всех авторов и все их книги, общее количество книг которых меньше 20.*/

delete from author
where author_id in(select author_id from book
       group by author_id
       having sum(amount) <20);
              
/* 6. Удалить все жанры, к которым относится меньше 4-х книг. В таблице book для этих жанров установить значение Null.*/

delete from genre
where genre_id in(select genre_id from book
                  group by genre_id
                  having count(title)<4)
                  
--ЗАПРОСЫ НА ВЫБОРКУ

/* 1. Вывести все заказы Баранова Павла (id заказа, какие книги, по какой цене и в каком количестве он заказал) в отсортированном по номеру заказа и названиям книг виде.*/

select buy.buy_id, title, price, buy_book.amount 
from 
    client 
    inner join buy on client.client_id= buy.client_id
    inner join buy_book on buy.buy_id=buy_book.buy_id
    inner join book on book.book_id=buy_book.book_id
where name_client = "Баранов Павел"
order by buy.buy_id, title;

/* 2. Посчитать, сколько раз была заказана каждая книга, для книги вывести ее автора (нужно посчитать, в каком количестве заказов фигурирует каждая книга).  Вывести фамилию и инициалы автора, название книги, последний столбец назвать Количество. Результат отсортировать сначала  по фамилиям авторов, а потом по названиям книг*/

select name_author, title, count(buy_book.amount) as "Количество"
from author
        inner join book USING(author_id)
        left join buy_book USING(book_id)
group by name_author, title
order by name_author, title;

/* 3. Вывести города, в которых живут клиенты, оформлявшие заказы в интернет-магазине. Указать количество заказов в каждый город, этот столбец назвать Количество. Информацию вывести по убыванию количества заказов, а затем в алфавитном порядке по названию городов*/

select name_city, count(buy.buy_id) as Количество
from city
    inner join client using(city_id)
    inner join buy using(client_id)
group by name_city
order by count(buy.buy_id) desc, name_city;

/* 4. Вывести номера всех оплаченных заказов и даты, когда они были оплачены.*/

select buy_id, date_step_end
from step inner join buy_step using (step_id)
where name_step = "Оплата" and date_step_end is not NULL

/* 5. Вывести информацию о каждом заказе: его номер, кто его сформировал (фамилия пользователя) и его стоимость (сумма произведений количества заказанных книг и их цены), в отсортированном по номеру заказа виде. Последний столбец назвать Стоимость.*/

select buy.buy_id, name_client, sum(buy_book.amount*price) as "Стоимость"
from client 
           inner join buy using(client_id)
           inner join buy_book using(buy_id)
           inner join book using(book_id)
group by buy.buy_id, name_client
order by buy.buy_id;

/* 6. Вывести номера заказов (buy_id) и названия этапов, на которых они в данный момент находятся. Если заказ доставлен –  информацию о нем не выводить. Информацию отсортировать по возрастанию buy_id.*/

select buy_id, name_step
from step inner join buy_step using(step_id)
where (date_step_beg is null and date_step_end is not null) 
        or (date_step_beg is not null and date_step_end is null)
order by buy_id;

/* 7. В таблице city для каждого города указано количество дней, за которые заказ может быть доставлен в этот город (рассматривается только этап "Транспортировка"). Для тех заказов, которые прошли этап транспортировки, вывести количество дней за которое заказ реально доставлен в город. А также, если заказ доставлен с опозданием, указать количество дней задержки, в противном случае вывести 0. В результат включить номер заказа (buy_id), а также вычисляемые столбцы Количество_дней и Опоздание. Информацию вывести в отсортированном по номеру заказа виде.*/

select buy.buy_id, DATEDIFF(date_step_end, date_step_beg) as 'Количество_дней', 
(if((DATEDIFF(date_step_end, date_step_beg)-days_delivery)<0,0,DATEDIFF(date_step_end, date_step_beg)-days_delivery)) as 'Опоздание'
from city inner join client using (city_id)
          inner join buy using (client_id)
          inner join buy_step using (buy_id)
                
where step_id = (select step_id from step where name_step= 'Транспортировка') and date_step_beg is not null and date_step_end is not null
order by buy_id;

/* 8. Выбрать всех клиентов, которые заказывали книги Достоевского, информацию вывести в отсортированном по алфавиту виде. В решении используйте фамилию автора, а не его id.*/

select distinct name_client
from author inner join book using (author_id)
            inner join buy_book using (book_id)
            inner join buy using (buy_id)
            inner join client using (client_id)
where name_author like '%Достоевский%'
order by name_client;

/* 9. Вывести жанр (или жанры), в котором было заказано больше всего экземпляров книг, указать это количество . Последний столбец назвать Количество.*/

select name_genre, sum(buy_book.amount) as 'Количество'
from genre inner join book using (genre_id)
            inner join buy_book using (book_id)
group by name_genre
having sum(buy_book.amount) = (select sum(buy_book.amount)
                                from genre inner join book using (genre_id)
                                            inner join buy_book using (book_id)
                                group by name_genre
                                limit 1);                                  
/* 10. Сравнить ежемесячную выручку от продажи книг за текущий и предыдущий годы. Для этого вывести год, месяц, сумму выручки в отсортированном сначала по возрастанию месяцев, затем по возрастанию лет виде. Название столбцов: Год, Месяц, Сумма.*/

SELECT YEAR(date_step_end) AS Год, MONTHNAME(date_step_end)AS Месяц,  SUM(price * buy_book.amount) AS Сумма
FROM buy_step
    INNER JOIN buy_book USING(buy_id)
    INNER JOIN book USING(book_id)
WHERE date_step_end IS NOT NULL AND step_id = 1
GROUP BY Год, Месяц
UNION ALL
SELECT YEAR(date_payment) AS Год, MONTHNAME(date_payment)AS Месяц, SUM(price*amount) AS Сумма
FROM buy_archive
GROUP BY Год, Месяц
ORDER BY Месяц ASC, Год ASC;

/* 11. Для каждой отдельной книги необходимо вывести информацию о количестве проданных экземпляров и их стоимости за 2020 и 2019 год . Вычисляемые столбцы назвать Количество и Сумма. Информацию отсортировать по убыванию стоимости.*/

select title, sum(Количество) as Количество, sum(Сумма) as Сумма
from
    (select book.title, sum(buy_archive.amount) as Количество, sum(buy_archive.price*buy_archive.amount) as Сумма
    from buy_archive inner join book using (book_id)
    group by book_id
    union 
    select book.title, sum(buy_book.amount)as Количество, sum(price*buy_book.amount)as Сумма
    from  book inner join buy_book using (book_id)
                inner join buy using (buy_id)
                inner join buy_step using (buy_id)
    WHERE date_step_end IS NOT NULL AND step_id = 1
    group by book_id) as main
group by title   
order by sum(Сумма) desc;

--ЗАПРОСЫ КОРРЕКТИРОВКИ

/* 1. Включить нового человека в таблицу с клиентами. Его имя Попов Илья, его email popov@test, проживает он в Москве.*/

insert into client(name_client, city_id, email)
values ('Попов Илья',(select city_id from city
where name_city = 'Москва'),'popov@test');

/* 2. оздать новый заказ для Попова Ильи. Его комментарий для заказа: «Связаться со мной по вопросу доставки».
Важно! В решении нельзя использоваться VALUES и делать отбор по client_id*/

INSERT INTO buy (buy_description, client_id)
SELECT 'Связаться со мной по вопросу доставки', client_id FROM client WHERE name_client='Попов Илья';

/* 3. Создать счет (таблицу buy_pay) на оплату заказа с номером 5, в который включить название книг, их автора, цену, количество заказанных книг и  стоимость. Последний столбец назвать Стоимость. Информацию в таблицу занести в отсортированном по названиям книг виде.*/

create table buy_pay AS
SELECT title, name_author, price, buy_book.amount, price*buy_book.amount as Стоимость
FROM author inner join book using (author_id)
            inner join buy_book using (book_id)
WHERE buy_book.buy_id = 5
order by title;

/* 4. Создать общий счет (таблицу buy_pay) на оплату заказа с номером 5. Куда включить номер заказа, количество книг в заказе (название столбца Количество) и его общую стоимость (название столбца Итого).  Для решения используйте ОДИН запрос.*/

create table buy_pay as
select buy_id, sum(buy_book.amount) as Количество, sum(buy_book.amount*price) as Итого
from book inner join buy_book using (book_id)
where buy_id=5;

/* 5. Завершить этап «Оплата» для заказа с номером 5, вставив в столбец date_step_end дату 13.04.2020, и начать следующий этап («Упаковка»), задав в столбце date_step_beg для этого этапа ту же дату.
Реализовать два запроса для завершения этапа и начале следующего. Они должны быть записаны в общем виде, чтобы его можно было применять для любых этапов, изменив только текущий этап. Для примера пусть это будет этап «Оплата».*/

UPDATE buy_step bs1,
       buy_step bs2
SET bs1.date_step_end = '2020-04-13',
    bs2.date_step_beg = '2020-04-13'
WHERE bs1.buy_id = 5
      AND bs2.buy_id = bs1.buy_id
      AND bs1.step_id = (SELECT step_id FROM step WHERE name_step = 'Оплата')
      AND bs2.step_id = bs1.step_id + 1;

SELECT * FROM buy_step
WHERE buy_id = 5;