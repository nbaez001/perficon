<?php

namespace App\Console\Commands;

use App\Mail\SendMail;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\Process\Exception\ProcessFailedException;
use Symfony\Component\Process\Process;

class BackupDatabase extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'db:backup';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Backup de la base de datos';

    protected $filename;
    protected $process;

    /**
     * Create a new command instance.
     *
     * @return void
     */
    public function __construct()
    {
        parent::__construct();
    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {
        // $date = Carbon::now()->format('Y-m-d_h-i');
        // $this->info($date);
        // $user = env('DB_USERNAME');
        // $password = env('DB_PASSWORD');
        // $database = env('DB_DATABASE');

        // $command = "mysqldump --user={$user} -p{$password} {$database} > {$date}.sql";
        // $this->info($command);
        // $process = new Process($command);
        // $process->start();

        // while($process->isRunning()){
        //     $s3 = Storage::disk('local');
        //     $s3->put('backups/'.$date.".sql", file_get_contents("{$date}.sql"));
        //     unlink("{$date}.sql");
        // }

        try {
            $filename = Carbon::now()->format('Y-m-d_h-i') . '.sql';
            $this->process = new Process(sprintf(
                'mysqldump -u%s -p%s %s > %s',
                config('database.connections.mysql.username'),
                config('database.connections.mysql.password'),
                config('database.connections.mysql.database'),
                storage_path("app/backups/{$filename}")
            ));

            if (!File::exists(storage_path() . "/app/backups")) {
                File::makeDirectory(storage_path() . '/app/backups');
            }

            $this->process->mustRun();

            $data = array(
                'destinatario' => 'nbaez001@gmail.com',
                'asunto' => 'Backup perficon ' . Carbon::now()->format('d-m-Y'),
                'mensaje' => 'Se  envia adjunto el backup de la BD Perficon.',
                'url' => "app/backups/{$filename}"
            );
            Mail::send(new SendMail($data));

            if (File::exists(storage_path() . "/app/backups/{$filename}")) {
                File::delete(storage_path() . "/app/backups/{$filename}");
            }
            $this->info('The backup has been proceed successfully.');
        } catch (ProcessFailedException $exception) {
            $this->error('The backup process has been failed.');
        }
    }
}
