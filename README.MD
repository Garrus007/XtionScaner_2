# XTion Scanner
Документация по программе сканирования стопы.

Рекомендую ознакомиться с файлами, лежащими в корне:
 - [Выступление.pdf](Выступление.pdf)
 - [Облако точек.pdf](Облако точек.pdf)

# Назначение программы:
Это программа должна делать:
 - [Получать облако точек от камеры глубины (Asus XTIon)](#get_cloud)
 - [По облаку построить поверхность (меш)](#make_mesh)
 - [Устранять дефекты облака](#remove_defects)
 - [Выделять из облако стопу](#get_foot)
 - [Строить 3D модель стельки](#make_model)
 - [Определять плоскостопие](#detect_flat)
 - [Позволять модиифицировать стельку](#modify)

## Подробнее:
<a name="get_cloud"></a>
### Получение данных от XTIon
 В принципе, можно получать данные прямо от камеры, есть в интернете примеры про
 кинект. В нашем случае реализован был пока следующий вариант: программа на C++
 с использованием OpenNI получает облако точек и сохраняет его в файл в специальном нашем
 формате [Organized Cloud File](#ocf_file). Программа читает этот файл (имя файла пока жетско забито в коде).

 Важно, что облако `организованное`, т.е не просто набор координат точек, а представляет
 собой матрицу, где каждому пикселю камеры соответствует точка в пространстве, заданная
 3мя координатами. И самое главное - соседние точки будут соседними элементами массива.
 На основе этого все у нас и работает.

Облако хранится в массиве векторов, отсуствие точки - `null`.

<a name="make_mesh"></a>
### По облаку построить поверхность (меш)

По облаку строится меш (сетка, полигоны, поверхность).
Приницп простейший, основан на организованности облака.

![](http://i.imgur.com/tDDEIDN.png)

Просто идем по облаку, соединяем не-null точки. Хитрость только в граничных точках, которые могут быть
треугольниками  в нескольких конфигурациях.

<a name="remove_defects"></a>
### Устранить дефекты облака
Полученное облако содержит множество дефектов:
 - рваные края объектов
 - дырки в объектах
 - неровная поверхность

 Эти дефекты надо устранить. Устранение дефектов - практически основная часть
 этой программы.

 Реализовано:
 - Заполнение отверстий
 - Сглаживание поверхности
 - Сгаживание краев (багает)

<a name="get_foot"></a>
### Выделять из облако стопу
В кадре не должно быть много объектов, но если все же будет - надо как-то выделять нужный  и удалять лишнее. У  нас есть методы, которые после детекции краев удаляют все за пределами края.

<a name="make_model"></a>
### Строить 3D модель стельки
Полученную поверхность надо преобразовать в стельку. Для этого она "выдавливается" на некую толщиу - получается основа. Так же нужно делать супинатор (твердую часть, под пяткой)

<a name="detect_flat"></a>
### Определять плоскостопие
Надо определять плоскостопие. Как-нибудь.

<a name="modify"></a>
### Позволять модиифицировать стельку
Если у человека плоскостопие, то надо стельку модифицировать, чтоб его исправлять - добавить изгиб.
Как-нибудь врач "вытягивет" может быть в нужном месте.

---------------------------------

# Как все работает
Программа написна на языке `Processing`. Это Java с кучей библиотек для графики.
Для очень легкой графиики.

```
Я повелся на простоту графической отладки и выбрал процессинг.
Он мне понравился, когда я его увидел.
Простите меня.

Processing IDE убогая, можете попробовать Atom с плагинами.

P.S. Перепишите на C#\Java\Что угодно, если хотите.
```
**Главный файл - XtionScanner.pde**

Самый главный класс - [`PointCloud`](#point_cloud). Хранит облако точек и его контур. Изначально после
создания облака контура нет, контур еще найти надо. Методы для этого есть.

Вот весь процесс обработки:
```Processing
//Получем облака
OCFReader cloud_reader = new OCFReader();
cloud=cloud_reader.OpenCloud("..\\Data\\cloud.OCF");
FindContour(cloud);

CloudClearer cc = new CloudClearer();           //Обрезатель контура
HoleFiller hf = new HoleFiller();               //Заполнятель дырок
ContourSmoother sm = new ContourSmoother();     //Сглаживатель контура

cloud = cc.CutCloud(cloud);                     //Обрезает контур
cloud = hf.Fill(cloud);                         //Заполняем
sm.SmoothContour(cloud, 10, 8, 0.3);            //Сглаживаем контур
cloud = cc.CutCloud(cloud);                     //Обрезаем по сглаженному, отсекая лишние бугры
cloud = hf.Fill(cloud);                         //Заполняем неровности контура

cloud = cloud.Smooth(20);                      //Сглаживание "поверхности"
```

<a name="ocf_file"></a>
## Формат OCF
Облако создает программа на C++ (черт, где она? Вышлю позже).

Формат файла:
```
[METADATA]
VERSION=1
WIDTH=640
HEIGHT=480
[DATA]
nan nan nan;nan x y z; x y z;nan nan nan;nan nan nan;
nan nan nan;nan x y z; x y z;nan nan nan;nan nan nan;
nan nan nan;nan x y z; x y z;nan nan nan;nan nan nan;
```
`VERSION` ни на что не влияет, `WIDTH`, `HEIGHT` - соответственно размеры облака.
Затем идет `HEIGHT` строк из `WIDTH` значений.
 - x y z - три float числа через пробел (разделитель - точка)
 - nan - точки нет.

За парсинг отвечает класс `OCFReader`. В описании класса так же есть информация
о формате.

## Важные классы
<a name="point_cloud"></a>
### PointCloud
Самый главный класс. Хранит облако точек. Облако хранится в виде двумерного массива
`PVector` (класс вектора из Processing).
Содержит контур - `ArrayList` из ИНДЕКСОВ точек.
Так же содержит ряд геттеров\\сеттеров для удобства доступа.

В процессе написание программы этот класс оброс рядом костылей для реализации каких-то
функций.
 - `boolean[][] is_contour` - второе представление контура (есть\\нет в точке)
 - методы клонирования облака, которые позволяют скопировать только облако без контура
 - Очистка контура

<a name="mesh"></a>
### Mesh
Класс, описывающий `очень специфическую и ограниченную` 3D модель.

Исчерпывающая документация доступна в коде.
```
  Все  точки, хранящиеся в меше, хранятся в списке PointCloud'ов
  Точки, находящиеся на разных "слоях" (на разной глубине), хранятся
  в разных PointCloud. Используется PointCloud вместо простого массива
  [][][], чтобы иметь возможность работы с контурами.
```
Имеет геттеры\\сеттеры.

`ОСТОРОЖНО: класс раздутый, включает в себя методы построения меша по облаку,
методы визуализации.`

### Вспомогательные классы
Тут стоит обратить внимание на такие велоспиеды как
 - `Point2D` Двумерная точка с целочисленными координатами с
  возможностью сдвигать ее на 1 клетку в заданном
  направлении
 - `Point3D` Трехмерная точка с целочисленными координатами
 - `Pair` Пара ключ-значение. Просто пара. Я не нашел готовую здесь.

 ----------------------------

## Методы обработки
<a name="contour_finder"></a>
### ContourFinder.pde
Принимает облако точек, находит ему контур (контур хранится в облаке).
```
Нахождение контура работает следующим образом:
 1. Двигаемся разверткой по матрице точек, до тех пор, пока не найдем
 первую существующую точку
 2. Эта точка будет самой верхней точкой контура - поэтому стартовое направление
 движения будет ВПРАВО
 3. Пытаемся найти точку В_НАПРАВЛЕНИИ_ДВИЖЕНИЯ от текущей. Если ее там нет - ищем
 как можно менее откланяющиеся от этого направления точки, при этом сначала
 стараемся найти точки, находящиеся как бы "вовне" контура, а затем, если не удалось
 - внутри
 4. Продолжаем так двигаться, пока не обойдем весь контур
```

Обратите внимание, что **КОНТУР НАЧИНАЕТ ОБХОДИТЬСЯ с САМОЙ ПЕРВОЙ НЕПУСТОЙ ТОЧКИ**
поэтому надо удалить мусор. Как-нибудь.

<a name="hole_filler"></a>
### HoleFiller.pde
Заполняет дырки в облаке. Есть еще HoleFiller_2.pde, это устаревшая реализация,
выкинуть ее.

Иллюстрация:
![](http://i.imgur.com/XoFUK1y.png)

```
Принцип работы:
Построчно сканирует облако в пределах контура.
В строке, если встречается разрыв, находит его границы и заполняет.

При проходе построчно возникает вопрос - с каких индексов в облаке начать?
Воспользуемся тем фактом, что точка 0 контура - САМАЯ ПЕРВАЯ ВСТРЕТИВШАЯСЯ НЕ ПУСТАТОЧКА.
Это одна из обязательных особенностей контура, поэтому мы можем начать с нее.
```

<a name="cloud_clearer"></a>
### CloudClearer.pde
Удаляет все точки (делает null), которые вне контура.
см. комментарии в файле. Далеко не лучшее решение.

<a name="cloud_smooth"></a>
### Сглаживает контур
Иллюстрация:
![](http://i.imgur.com/RPLYi9k.png)

Важно отметить, что надо сглаживать и координаты точек, и их индексы.
Если сгладить только координаты, то точки сместятся, а индексы останутся, и нарушится главное правило - соответствие расположения точек в пространстве и их индексов в массиве.

Поэтому после сглаживания, происходит вычисление новых индексов после вычисления координинат. Это немного не точно, видно отслаивание контура от модели на скрине.

```
Вычисление координат по индексам
x = x0 + i*dx
y = y0 + j*dx

Вычисление индексов новых точек
i' = (x' - x0)/dx
j' = (y' - y0)/dy
```

После сглаживания мы получим ситуацию, когда часть точек оказывается ВНЕ контура, а часть внутри контура - незаполнены.
![](http://i.imgur.com/EsTXS2m.png)

Поэтому надо применять потом методы [`ClearContour`](#cloud_clearer) и [`Fill`](#hole_filler)

```
ВНИМАНИЕ: ПОРЯДОК ИМЕЕТ ЗНАЧЕНИЕ
Метод Fill портит контур - заново находит его
по внешим точкам. Поэтому он зальет внутренние точки
и отрезанные снова включит в контур
```
