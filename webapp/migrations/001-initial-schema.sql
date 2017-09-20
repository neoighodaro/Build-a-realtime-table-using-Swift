-- Up
CREATE TABLE Users (
    id INTEGER NOT NULL,
    name TEXT,
    position INTEGER NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);
INSERT INTO Users (id, name, position) VALUES (1, 'John Doe', 1);

-- Down
DROP TABLE Users;
