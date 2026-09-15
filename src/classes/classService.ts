import { getSupabaseClient } from '../lib/supabase';

export type GradeLevel = 10 | 11 | 12;

export type ClassRecord = {
  id: string;
  name: string;
  grade: GradeLevel;
  joinCode: string;
};

export type ClassMembership = {
  classId: string;
  studentId: string;
  status: 'active' | 'suspended' | 'removed';
};

export type ClassGateway = {
  rpc(
    name: string,
    args: Record<string, unknown>,
  ): Promise<{ data: unknown; error: Error | null }>;
};

type CreateClassRow = {
  class_id: string;
  class_name: string;
  class_grade: GradeLevel;
  join_code: string;
};

type MembershipRow = {
  class_id: string;
  student_id: string;
  status: ClassMembership['status'];
};

function getDefaultGateway(): ClassGateway {
  return {
    async rpc(name, args) {
      const { data, error } = await getSupabaseClient().rpc(name, args);
      return { data, error };
    },
  };
}

function firstRow<T>(data: unknown, operation: string): T {
  if (!Array.isArray(data) || data.length === 0 || data[0] == null) {
    throw new Error(`${operation} returned no data.`);
  }
  return data[0] as T;
}

function normalizeClassName(name: string): string {
  const normalized = name.trim();
  if (!normalized) {
    throw new Error('Class name is required.');
  }
  return normalized;
}

function assertGrade(grade: number): asserts grade is GradeLevel {
  if (grade !== 10 && grade !== 11 && grade !== 12) {
    throw new Error('Grade must be 10, 11, or 12.');
  }
}

function normalizeJoinCode(joinCode: string): string {
  const normalized = joinCode.trim().toUpperCase();
  if (!normalized) {
    throw new Error('Join code is required.');
  }
  return normalized;
}

export async function createClass(
  input: { name: string; grade: GradeLevel },
  gateway: ClassGateway = getDefaultGateway(),
): Promise<ClassRecord> {
  const name = normalizeClassName(input.name);
  assertGrade(input.grade);

  const { data, error } = await gateway.rpc('create_class_with_code', {
    p_name: name,
    p_grade: input.grade,
  });

  if (error) throw error;

  const row = firstRow<CreateClassRow>(data, 'Class creation');
  return {
    id: row.class_id,
    name: row.class_name,
    grade: row.class_grade,
    joinCode: row.join_code,
  };
}

export async function rotateJoinCode(
  classId: string,
  gateway: ClassGateway = getDefaultGateway(),
): Promise<{ joinCode: string }> {
  const normalizedClassId = classId.trim();
  if (!normalizedClassId) {
    throw new Error('Class ID is required.');
  }

  const { data, error } = await gateway.rpc('rotate_class_join_code', {
    p_class_id: normalizedClassId,
  });

  if (error) throw error;

  if (typeof data === 'string' && data.trim()) {
    return { joinCode: data };
  }

  if (Array.isArray(data) && data[0] && typeof data[0].join_code === 'string') {
    return { joinCode: data[0].join_code };
  }

  throw new Error('Join-code rotation returned no data.');
}

export async function joinClass(
  joinCode: string,
  gateway: ClassGateway = getDefaultGateway(),
): Promise<ClassMembership> {
  const normalized = normalizeJoinCode(joinCode);
  const { data, error } = await gateway.rpc('join_class_by_code', {
    p_code: normalized,
  });

  if (error) throw error;

  const row = firstRow<MembershipRow>(data, 'Class join');
  return {
    classId: row.class_id,
    studentId: row.student_id,
    status: row.status,
  };
}
