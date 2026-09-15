import { describe, expect, test } from 'vitest';
import {
  createClass,
  joinClass,
  rotateJoinCode,
  type ClassGateway,
} from '../../src/classes/classService';

function gatewayWith(
  responder: ClassGateway['rpc'],
): ClassGateway {
  return { rpc: responder };
}

describe('classService', () => {
  test('creates a class through the secure RPC and maps the returned join code', async () => {
    const calls: Array<[string, Record<string, unknown>]> = [];
    const gateway = gatewayWith(async (name, args) => {
      calls.push([name, args]);
      return {
        data: [{
          class_id: 'class-1',
          class_name: '11A1 Pronunciation',
          class_grade: 11,
          join_code: 'AB12CD34',
        }],
        error: null,
      };
    });

    await expect(
      createClass({ name: '11A1 Pronunciation', grade: 11 }, gateway),
    ).resolves.toEqual({
      id: 'class-1',
      name: '11A1 Pronunciation',
      grade: 11,
      joinCode: 'AB12CD34',
    });

    expect(calls).toEqual([
      ['create_class_with_code', { p_name: '11A1 Pronunciation', p_grade: 11 }],
    ]);
  });

  test('rotates a class code through the owner-only RPC', async () => {
    const gateway = gatewayWith(async (name, args) => {
      expect(name).toBe('rotate_class_join_code');
      expect(args).toEqual({ p_class_id: 'class-1' });
      return { data: 'ZX90YU12', error: null };
    });

    await expect(rotateJoinCode('class-1', gateway)).resolves.toEqual({
      joinCode: 'ZX90YU12',
    });
  });

  test('normalizes student join codes and returns the active membership', async () => {
    const gateway = gatewayWith(async (name, args) => {
      expect(name).toBe('join_class_by_code');
      expect(args).toEqual({ p_code: 'AB12CD34' });
      return {
        data: [{
          class_id: 'class-1',
          student_id: 'student-1',
          status: 'active',
        }],
        error: null,
      };
    });

    await expect(joinClass('  ab12cd34  ', gateway)).resolves.toEqual({
      classId: 'class-1',
      studentId: 'student-1',
      status: 'active',
    });
  });

  test('rejects empty join codes before making an RPC call', async () => {
    let called = false;
    const gateway = gatewayWith(async () => {
      called = true;
      return { data: [], error: null };
    });

    await expect(joinClass('   ', gateway)).rejects.toThrow(/join code is required/i);
    expect(called).toBe(false);
  });

  test('surfaces database authorization or invalid-code errors', async () => {
    const gateway = gatewayWith(async () => ({
      data: null,
      error: new Error('Invalid or inactive class code'),
    }));

    await expect(joinClass('BADCODE', gateway)).rejects.toThrow(
      /invalid or inactive class code/i,
    );
  });
});
