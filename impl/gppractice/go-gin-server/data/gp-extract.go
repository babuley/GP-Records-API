package data

import (
	"runtime"
	"bufio"
	"encoding/csv"
	"encoding/json"
	"io"
	"log"
	"os"
	"path"
)

func init() {
	_, filename, _, _ := runtime.Caller(0)
	currentPath := path.Dir(filename)
	fullpath := path.Join(currentPath, "./../data", "egpcur.csv")
	gps, _ := loadFromCSV(fullpath)
	records = gps

}

var records []GPRecord


//GPRecord holds info on GP and their practice
type GPRecord struct {
	GmcCode      string `json:"gmcCode"`
	Name         string `json:"name"`
	Address      string `json:"address"`
	PostCode     string `json:"postCode"`
	PracticeCode string `json:"practiceCode"`
}

func loadFromCSV(fileName string) ([]GPRecord, error) {
	gpCsv, _ := os.Open(fileName)
	reader := csv.NewReader(bufio.NewReader(gpCsv))

	var gps []GPRecord
	for {
		line, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		gps = append(gps, GPRecord{
			GmcCode:      line[0],
			Name:         line[1],
			Address:      line[4] + line[5] + line[6] + line[7] + line[8],
			PostCode:     line[9],
			PracticeCode: line[14],
		})
	}
	return gps, nil
}

//GetGPRecords - Get GP Records
func GetGPRecords() ([]GPRecord) {
	return records
}

//GetGPRecordsByGMC - Get GP Records by GMC code
func GetGPRecordsByGMC(gmcCode string) ([]GPRecord, error) {
	var gmc []GPRecord
	for _, item := range records {
		if item.GmcCode == gmcCode {
			gmc = append(gmc, item)
		}
	}
	return gmc, nil
}

//GPRecordsToJSON - marshal to JSON
func GPRecordsToJSON(records []GPRecord) string {
	js, error := json.Marshal(records)
	if error != nil {
		return ""
	}
	return string(js)

}

