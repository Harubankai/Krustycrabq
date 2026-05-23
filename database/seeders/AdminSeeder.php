<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Check if admin already exists
        $exists = User::where('email', 'admin@gmail.com')->exists();
        if ($exists) {
            $this->command->info('Admin user already exists. Skipping.');
            return;
        }

        User::create([
            'name' => 'Admin',
            'email' => 'admin@gmail.com',
            'password' => Hash::make('admin123'),
            'role' => 'admin',
        ]);
        $this->command->info('Admin user created successfully.');
    }
}
