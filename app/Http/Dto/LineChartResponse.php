<?php

namespace App\Http\Dto;

class LineChartResponse
{
    public $label;
    public $data;
    public $dataIngMov;
    public $dataIng;

    public function getLabel()
    {
        return $this->label;
    }

    public function setLabel($label)
    {
        $this->label = $label;
    }

    public function getData()
    {
        return $this->data;
    }

    public function setData($data)
    {
        $this->data = $data;
    }

    public function getDataIngMov()
    {
        return $this->dataIngMov;
    }

    public function setDataIngMov($dataIngMov)
    {
        $this->dataIngMov = $dataIngMov;
    }

    public function getDataIng()
    {
        return $this->dataIng;
    }

    public function setDataIng($dataIng)
    {
        $this->dataIng = $dataIng;
    }
}
