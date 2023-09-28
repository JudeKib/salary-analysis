import psycopg2
import csv


def get_raw_data():
    db_params = {
        'host': redacted,
        'port': redacted,
        'database': redacted,
        'user': redacted,
        'password': redacted
    }

    connection = psycopg2.connect(**db_params)
    cursor = connection.cursor()

    query = "SELECT *, RIGHT(TRIM(TRAILING FROM location), 2) state, job_title LIKE 'SR %' is_sr, CASE WHEN job_title LIKE 'SR %' THEN SUBSTRING(job_title, 4, LENGTH(job_title)) ELSE job_title END base_job_title FROM h1b_salary.salaries;"
    # Query selects all data plus three additional columns:
    #   state          | str  | the state where the job is located
    #   is_sr          | bool | whether the job is a senior position
    #   base_job_title | str  | the job title without the 'SR' suffix
    cursor.execute(query)

    data = [[desc[0] for desc in cursor.description]]
    data.extend(cursor.fetchall())
        
    cursor.close()
    connection.close()

    return data


def correct_case(title):
    new_title = ''
    for word in title.split():
        if len(word) > 1:
            word = word[0].upper() + word[1:].lower()
        new_title = new_title + word + ' '
    return new_title.strip()


def process_data(data):
    header = data[0]
    print(header)
    num_cols = len(header)
    cleaned_data = []
    title_idx = header.index('job_title')
    base_title_idx = header.index('base_job_title')

    for row in data:    
        job_title = row[title_idx]
        base_title = row[base_title_idx]

        cleaned_row = tuple(correct_case(job_title) if idx == title_idx 
                            else correct_case(base_title) if idx == base_title_idx 
                            else row[idx] 
                            for idx in range(num_cols))
        cleaned_data.append(cleaned_row)

    return cleaned_data


def write_data(cleaned_data):
    csv_path = 'C:\\Users\\kjude\\salary_data_clean.csv'

    with open(csv_path, 'w', newline='', encoding='utf-8') as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerows(cleaned_data)


if __name__ == '__main__':
    raw_data = get_raw_data()
    cleaned_data = process_data(raw_data)
    write_data(cleaned_data)
