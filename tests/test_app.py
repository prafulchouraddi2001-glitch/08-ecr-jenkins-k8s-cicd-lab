import json
import unittest
from threading import Thread
from urllib.request import urlopen
from urllib.error import HTTPError

from app.app import AppHandler, HTTPServer


class AppTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = HTTPServer(("127.0.0.1", 0), AppHandler)
        cls.port = cls.server.server_address[1]
        cls.thread = Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base_url = f"http://127.0.0.1:{cls.port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)

    def test_home_returns_service_information(self):
        with urlopen(self.base_url + "/") as response:
            data = json.loads(response.read())
            self.assertEqual(response.status, 200)
            self.assertEqual(data["service"], "project-8-cicd-lab")

    def test_health_returns_healthy(self):
        with urlopen(self.base_url + "/health") as response:
            data = json.loads(response.read())
            self.assertEqual(response.status, 200)
            self.assertEqual(data["status"], "healthy")

    def test_unknown_route_returns_404(self):
        with self.assertRaises(HTTPError) as error:
            urlopen(self.base_url + "/unknown")
        response = error.exception
        try:
            self.assertEqual(response.code, 404)
        finally:
            response.close()


if __name__ == "__main__":
    unittest.main()
