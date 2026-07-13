import * as SQLite from 'expo-sqlite';

export type CueMode = 'beep' | 'vibration';

export type IntervalProgramInput = {
  cueMode: CueMode;
  name: string;
  prepareSeconds: number;
  restSeconds: number;
  rounds: number;
  workSeconds: number;
};

export type IntervalProgram = IntervalProgramInput & {
  createdAt: string;
  id: number;
};

type IntervalProgramRow = {
  created_at: string;
  cue_mode: CueMode;
  id: number;
  name: string;
  prepare_seconds: number;
  rest_seconds: number;
  rounds: number;
  work_seconds: number;
};

let databasePromise: Promise<SQLite.SQLiteDatabase> | null = null;

function getDatabase() {
  databasePromise ??= SQLite.openDatabaseAsync('tempo.db');
  return databasePromise;
}

type TableInfoRow = {
  name: string;
  type: string;
};

function mapRow(row: IntervalProgramRow): IntervalProgram {
  return {
    createdAt: row.created_at,
    cueMode: row.cue_mode,
    id: row.id,
    name: row.name,
    prepareSeconds: row.prepare_seconds,
    restSeconds: row.rest_seconds,
    rounds: row.rounds,
    workSeconds: row.work_seconds,
  };
}

export function formatDuration(totalSeconds: number) {
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  return [hours, minutes, seconds].map((value) => String(value).padStart(2, '0')).join(':');
}

export async function initializeIntervalProgramStore() {
  const database = await getDatabase();
  const tableInfo = await database.getAllAsync<TableInfoRow>('PRAGMA table_info(interval_programs)');

  if (tableInfo.length > 0 && tableInfo.find((column) => column.name === 'id')?.type.toUpperCase() !== 'INTEGER') {
    await database.execAsync(`
      ALTER TABLE interval_programs RENAME TO interval_programs_legacy;

      CREATE TABLE interval_programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        prepare_seconds INTEGER NOT NULL,
        work_seconds INTEGER NOT NULL,
        rest_seconds INTEGER NOT NULL,
        rounds INTEGER NOT NULL,
        cue_mode TEXT NOT NULL,
        created_at TEXT NOT NULL
      );

      INSERT INTO interval_programs (
        name,
        prepare_seconds,
        work_seconds,
        rest_seconds,
        rounds,
        cue_mode,
        created_at
      )
      SELECT
        name,
        prepare_seconds,
        work_seconds,
        rest_seconds,
        rounds,
        cue_mode,
        created_at
      FROM interval_programs_legacy;

      DROP TABLE interval_programs_legacy;
    `);

    return;
  }

  await database.execAsync(`
    CREATE TABLE IF NOT EXISTS interval_programs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      prepare_seconds INTEGER NOT NULL,
      work_seconds INTEGER NOT NULL,
      rest_seconds INTEGER NOT NULL,
      rounds INTEGER NOT NULL,
      cue_mode TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
  `);
}

export async function createIntervalProgram(input: IntervalProgramInput) {
  await initializeIntervalProgramStore();

  const database = await getDatabase();
  const createdAt = new Date().toISOString();

  const result = await database.runAsync(
    `INSERT INTO interval_programs (
      name,
      prepare_seconds,
      work_seconds,
      rest_seconds,
      rounds,
      cue_mode,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
    input.name,
    input.prepareSeconds,
    input.workSeconds,
    input.restSeconds,
    input.rounds,
    input.cueMode,
    createdAt,
  );

  return { ...input, createdAt, id: result.lastInsertRowId };
}

export async function updateIntervalProgram(id: number, input: IntervalProgramInput) {
  await initializeIntervalProgramStore();

  const database = await getDatabase();

  await database.runAsync(
    `UPDATE interval_programs
    SET
      name = ?,
      prepare_seconds = ?,
      work_seconds = ?,
      rest_seconds = ?,
      rounds = ?,
      cue_mode = ?
    WHERE id = ?`,
    input.name,
    input.prepareSeconds,
    input.workSeconds,
    input.restSeconds,
    input.rounds,
    input.cueMode,
    id,
  );
}

export async function deleteIntervalProgram(id: number) {
  await initializeIntervalProgramStore();

  const database = await getDatabase();

  await database.runAsync('DELETE FROM interval_programs WHERE id = ?', id);
}

export async function listIntervalPrograms() {
  await initializeIntervalProgramStore();

  const database = await getDatabase();
  const rows = await database.getAllAsync<IntervalProgramRow>(
    `SELECT
      id,
      name,
      prepare_seconds,
      work_seconds,
      rest_seconds,
      rounds,
      cue_mode,
      created_at
    FROM interval_programs
    ORDER BY datetime(created_at) DESC`,
  );

  return rows.map(mapRow);
}

export async function getIntervalProgram(id: number) {
  await initializeIntervalProgramStore();

  const database = await getDatabase();
  const row = await database.getFirstAsync<IntervalProgramRow>(
    `SELECT
      id,
      name,
      prepare_seconds,
      work_seconds,
      rest_seconds,
      rounds,
      cue_mode,
      created_at
    FROM interval_programs
    WHERE id = ?`,
    id,
  );

  return row ? mapRow(row) : null;
}
